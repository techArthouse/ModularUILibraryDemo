//
//  RecipesViewModel.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI
import Combine

@MainActor
class RecipesViewModel: ObservableObject {
    enum LoadPhase: Equatable {
        case idle
        case loading
        case success(LoadSuccess)
        case failure(String)
        
        // LoadSuccess is a signal of where did we load from.
        enum LoadSuccess: Equatable {
            case itemsLoaded([Recipe])     // Simple reassign
            case itemsFiltered([UUID])   // Mutate items in place for view identity
            case itemsEmpty
        }
    }

    @Published var items: [RecipeItem] = []
    @Published var loadPhase: LoadPhase = .idle
    private var cancellables = Set<AnyCancellable>()
    
    // Search and Filtering
    @Published var searchQuery: String = ""
    @Published var selectedCuisine: String?
    @Published var searchModel: SearchViewModel?
    
    let recipeStore: any RecipeDataServiceProtocol
    private let filterStrategy: RecipeFilterStrategy
    private let networkService: any NetworkServiceProtocol
    
    // MARK: - Init
    
    init(recipeStore: any RecipeDataServiceProtocol, filterStrategy: RecipeFilterStrategy, networkService: any NetworkServiceProtocol) {
        self.recipeStore = recipeStore
        self.filterStrategy = filterStrategy
        self.networkService = networkService
        
        subscribe()
    }
    
    /// The 1st subscription keeps items synced with recipes source of truth.
    /// the 2nd listens to filter options and mutates items in place to determine if item should be showed.
    /// By modifying in place we preserve swiftui's internal identity property and keeps animations intact.
    private func subscribe() {
        // 1. updates the items list with new recipes (used for response to network fetching recipes)
        recipeStore
            .itemsPublisher
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] recipes in
                guard let self = self else { return }
                self.loadPhase = .success(.itemsLoaded(recipes))
            }
            .store(in: &cancellables)
        
        // 2. performs filtering through search/filtering options
        Publishers
            .CombineLatest(
                $selectedCuisine.removeDuplicates(),
                $searchQuery.removeDuplicates()
            )
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                guard let self = self else { return }
                let visibleIDs = self
                    .filterStrategy
                    .filter(recipeStore.allItems,
                            cuisine: selectedCuisine,
                            query: searchQuery)
                
                Logger.log("visibleIDs: \(visibleIDs)")
                self.loadPhase = .success(.itemsFiltered(visibleIDs))
            }
            .store(in: &cancellables)
        
        // 3. Centralizes item assignment and in place mutations.
        $loadPhase
            .receive(on: RunLoop.main)
            .sink { [weak self] phase in
                guard let self = self else { return }
                
                switch phase {
                case .success(.itemsLoaded(let recipes)):
                    let filtered = filterStrategy.isFavorite
                    ? recipes.filter { self.recipeStore.isFavorite(for: $0.id) }
                    : recipes
                    
                    let newItems = filtered.map {
                        let item = RecipeItem($0)
                        item.shouldShow = true
                        return item
                    }
                    self.items = newItems
                    if newItems.isEmpty {
                        self.loadPhase = .success(.itemsEmpty)
                    }
                    
                case .success(.itemsFiltered(let ids)):
                    for (i, item) in self.items.enumerated() {
                        self.items[i].shouldShow = ids.contains(item.id)
                    }
                    
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// Called on first appearance. Start the cache and load recipes.
    func loadAll() async {
        loadPhase = .loading
        await self.loadRecipes()
    }
    
    func reloadAll() async {
        loadPhase = .loading
        
        await recipeStore.refreshImageCache() // clear imagecache
        await self.loadRecipes()
        self.searchQuery = ""
        self.selectedCuisine = nil
        self.searchModel = nil
    }
    
    func openFilterOptions() {
        self.searchModel = SearchViewModel(text: self.searchQuery, categories: self.cusineCategories)
    }
    
    func applyFilters(cuisine: String?) {
        self.selectedCuisine = cuisine
    }
    
    var cusineCategories: [String] {
        var categories = Set<String>() // No duplicates
        let selectedItemIds = items.filter(\.shouldShow).map { $0.id }
        
        // Choose the recipes that are set to show and gather all their cuisines.
        for item in recipeStore.allItems.filter({ selectedItemIds.contains($0.id) }) {
            categories.insert(item.cuisine)
        }
        return Array(categories.sorted(by: <))
    }
    
    /// Load and wrap your recipes in order
    func loadRecipes() async {
        do {
            guard let url = URL(string: NetworkEndpoint.root.rawValue) else {
                return
            }
            let data = try await networkService.requestData(from: url, using: .get)
            let list = try JSONDecoder().decode(RecipeList.self, from: data)
            let recipes = list.recipes + list.invalidRecipes
//            var recipes = try await Recipe.allFromJSON(using: .good)
            recipeStore.setRecipes(recipes: recipes)
        } catch {
            loadPhase = .failure(error.localizedDescription)
        }
    }
}

struct SearchViewModel: Identifiable {
    var id: String { text }
    var text: String
    var categories: [String] = []
}
