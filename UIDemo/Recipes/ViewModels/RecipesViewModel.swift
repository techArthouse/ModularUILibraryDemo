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
        case success
        case failure(String)
    }

    @Published var items: [RecipeItem] = []
    @Published var loadPhase: LoadPhase = .idle
    
    @Published var searchQuery: String = ""
    @Published var selectedCuisine: String?
    @Published var searchModel: SearchViewModel?

    private let networkService: NetworkServiceProtocol
    var recipeStore: any RecipeDataServiceProtocol
    private let filterStrategy: RecipeFilterStrategy
    private var cancellables = Set<AnyCancellable>()
    let filterTrigger = PassthroughSubject<Void, Never>()
    
    let recipesLoadedTrigger = PassthroughSubject<Void, Never>()
    
    // MARK: - Init
    
    init(recipeStore: any RecipeDataServiceProtocol, filterStrategy: RecipeFilterStrategy, networkService: NetworkServiceProtocol) {
        self.recipeStore = recipeStore
        self.filterStrategy = filterStrategy
        self.networkService = networkService
        
        subscribe()
    }
    
    /// The 1st subscription keeps items synced with recipes source of truth.
    /// the 2nd listens to filter options and mutates items in place to determine if item should be showed.
    /// By modifying in place we preserve swiftui's internal identity property and keeps animations intact.
    private func subscribe() {
        // 1.
        recipeStore
            .itemsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] recipes in
                guard let self = self else { return }
                // create one RecipeItem per recipe. no filter
                self.items = recipes.map { recipe in
                    let item = RecipeItem(recipe)
                    return item
                }
                self.applyFilter(animated: false)
            }
            .store(in: &cancellables)
        
        // 2.
        Publishers
            .CombineLatest(
                $selectedCuisine,
                $searchQuery // .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.applyFilter(animated: true)
            }
            .store(in: &cancellables)
    }
    
    private func applyFilter(animated: Bool) {
        // computes which recipe ids should be visible
        let visibleIDs = self.filterStrategy.filter(recipeStore.allItems,
                                                    cuisine: selectedCuisine,
                                                    query: searchQuery).filter({ id in
            if self.filterStrategy.isFavorite {
                return self.recipeStore.isFavorite(for: id)
            } else {
                return true
            }
        })
        
        // update each item's `selected` in place to preserve animations and prevent odd ui flickers
        for (idx, item) in items.enumerated() {
            let shouldShow = visibleIDs.contains(item.id)
            
            if animated {
                // stagger them by index for a “fan-out” effect (TODO: - animation not reflecting fan out)
                let delay = Double(idx) * 0.03
                withAnimation(.easeInOut.delay(delay)) {
                    items[idx].selected = shouldShow
                }
            } else {
                items[idx].selected = shouldShow
            }
        }
    }
    
    // MARK: - Public API
    
    /// Called on first appearance. Start the cache and load recipes.
    func loadAll() {
        loadPhase = .loading

        Task {
            do {
                try await self.loadRecipes()
                loadPhase = .success
            }
            catch {
                loadPhase = .failure(error.localizedDescription)
            }
        }
    }
    
    func reloadAll() async {
        loadPhase = .loading
        
        do {
            try await Task.sleep(for: .seconds(0.5)) // for UX feedback
            await recipeStore.refreshImageCache() // clear imagecache
            try await self.loadRecipes()
            self.searchQuery = ""
            self.selectedCuisine = nil
            self.searchModel = nil
            loadPhase = .success
        }
        catch {
            loadPhase = .failure(error.localizedDescription)
        }
    }
    
    var cusineCategories: [String] {
        var categories = Set<String>()
        let itemIds = self.items.filter({ item in
            item.selected
        }).map { $0.id }
        for item in recipeStore.allItems.filter({ itemIds.contains($0.id) }) {
            categories.insert(item.cuisine)
        }
        return Array(categories)
    }
    
    /// Load and wrap your recipes in order
    internal func loadRecipes(from url: URL? = nil) async throws {
        do {
            //        FetchCache.shared.load()
            let data = try await networkService.requestData(from: url ?? URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!, using: .get)
            
            let list = try JSONDecoder().decode(RecipeList.self, from: data)
            
            let recipes = list.recipes + list.invalidRecipes
            recipeStore.setRecipes(recipes: recipes)
        } catch {
            throw RecipeDecodeError.unexpectedErrorWithDataModel("")
        }
    }
}

struct SearchViewModel: Identifiable {
    var id: String { text }
    var text: String
    var categories: [String] = []
}


@MainActor
protocol RecipeDataConsumer {
    var items: [RecipeItem] { get }
    var recipeStore: RecipeDataService { get }
    func loadRecipes(from url: URL?) async throws
}



extension RecipesViewModel: Filterable {
    func filterSend() {
        filterTrigger.send()
    }
}
    
@MainActor
protocol Filterable {
    func filterSend()
}
