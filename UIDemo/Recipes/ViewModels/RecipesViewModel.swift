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

    private let networkService: any NetworkServiceProtocol
    @Published var recipeStore: any RecipeDataServiceProtocol
    private let filterStrategy: RecipeFilterStrategy
    private var cancellables = Set<AnyCancellable>()
    let filterTrigger = PassthroughSubject<Void, Never>()
    
    let recipesLoadedTrigger = PassthroughSubject<Void, Never>()
    
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
                print("apfilt recieving itempublisher\n")
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
        print("apfilt 🧠 Favorite check for D1:", recipeStore.isFavorite(for: UUID(uuidString: "74F6D4EB-DA50-4901-94D1-DEAE2D8AF1D1")!))

        let visibleIDs = self.filterStrategy.filter(recipeStore.allItems,
                                                    cuisine: selectedCuisine,
                                                    query: searchQuery).filter({ id in
            if self.filterStrategy.isFavorite {
                print("apfilt is fav \(self.recipeStore.isFavorite(for: id))")
                return self.recipeStore.isFavorite(for: id)
            } else {
                return true
            }
        })
        
        
        print("apfilt Store favorites: \(recipeStore.memoryDataSource.memories.filter { $0.value.isFavorite })")
        
        // update each item's `selected` in place to preserve animations and prevent odd ui flickers
        for (idx, item) in items.enumerated() {
            let shouldShow = visibleIDs.contains(item.id)
            print("apfilt Favorites VM is filtering on IDs: \(visibleIDs)")

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
    func loadAll() async {
        loadPhase = .loading
        await self.loadRecipes()
    }
    
    func reloadAll() async {
        loadPhase = .loading
        
//        do {
//            try await Task.sleep(for: .seconds(0.5)) // for UX feedback
//        }
//        catch {
//            // just continue
//        }
        
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
        var categories = Set<String>()
        let selectedItemIds = items.filter(\.selected).map { $0.id }
        for item in recipeStore.allItems.filter({ selectedItemIds.contains($0.id) }) {
            categories.insert(item.cuisine)
        }
        return Array(categories)
    }
    
    /// Load and wrap your recipes in order
    internal func loadRecipes(from url: URL? = nil) async {
        do {
//            let data = try await networkService.requestData(from: url ?? URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!, using: .get)
//            
//            let list = try JSONDecoder().decode(RecipeList.self, from: data)
//            
//            let recipes = list.recipes + list.invalidRecipes
//            self.items = []
            
            let data = try await Recipe.allFromJSON(using: .good)
            recipeStore.setRecipes(recipes: data)
            loadPhase = .success
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
