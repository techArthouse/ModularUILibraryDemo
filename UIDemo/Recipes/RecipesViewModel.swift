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
    @Published var items: [RecipeItem] = []
    @Published var searchQuery: String = ""
    @Published var selectedCuisine: String?
    @Published var searchModel: SearchViewModel? /// TODO: - track this var to implement how to apply filters. 
    
    private var allItems: [RecipeItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let cache: RecipeCacheProtocol
    private let memoryStore: RecipeMemoryStoreProtocol
    
    // We want the vm to always instantiate to not break consumers, but we should also allow for default no action and later load based on new urlString
//    init() {
//        Publishers.CombineLatest(
//            $searchQuery
//                .prepend("") // ensure searchQuery emits immediately
//                .debounce(for: .milliseconds(300), scheduler: RunLoop.main),
//            $selectedCuisine
//        )
//        .sink { [weak self] (query, cuisine) in
//            print("Filters updated query: \(query), cuisine: \(cuisine)")
//            self?.applyFilters(query: query, cuisine: cuisine)
//        }
//        .store(in: &cancellables)
//        $selectedCuisine
//            .sink { [weak self] cuisine in
//                print("Selected cuisine: \(cuisine ?? "nil")")
//                self?.applyFilters(query: self?.searchQuery ?? "", cuisine: cuisine)
//            }
//            .store(in: &cancellables)
//        
//    }
    
    // MARK: - Init
    init(cache: RecipeCacheProtocol, memoryStore: RecipeMemoryStoreProtocol) {
        self.cache = cache
        self.memoryStore = memoryStore
        
        $selectedCuisine
            .sink { [weak self] cuisine in
                print("Selected cuisine: \(cuisine ?? "nil")")
                self?.applyFilters(query: self?.searchQuery ?? "", cuisine: cuisine)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filter Logic
    private func applyFilters(query: String, cuisine: String?) {
        guard cuisine != nil else {
            return
        }

        var result = allItems
        if !query.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        if let cuisine = cuisine {
            items = result.filter {
                let include = $0.cuisine.lowercased() == cuisine.lowercased()
                print("Matched \(include): \($0.name)")
                return include
            }
        }
        searchModel = nil
    }
    
    // MARK: - Public API
    
    /// Start FetchCache using pathComponent.
    /// Succeeds unless any error occurs in the cache initialization procees. throws a verbose error if fails.
    /// the error
    func startCache(path: String) throws {
        print("Starting cache at path: \(path)")
        try cache.openCacheDirectoryWithPath(path: path)
    }
    
    func syncRecipeMemoryStore(item: RecipeItem) {
//        items = items.map { item in
//            var decorated = item
//            decorated.isFavorite = memoryStore.isFavorite(for: item.id)
//            decorated.notes = memoryStore.notes(for: item.id)
//            return decorated
//        }
        item.isFavorite = memoryStore.isFavorite(for: item.id)
        item.notes =  memoryStore.notes(for: item.id)
    }
    
    func toggleFavorite(recipeUUID: UUID) {
        memoryStore.toggleFavorite(recipeUUID: recipeUUID)
    }
    
#if DEBUG
    
    /// Load and wrap your recipes in order
    func loadRecipes(from url: URL? = nil) async {
        let recipes = await Recipe.allFromJSON(using: .good) // Network call
        self.allItems.append(contentsOf: recipes.map ({ recipe in
            var recipeItem = RecipeItem(recipe: recipe)
            syncRecipeMemoryStore(item: recipeItem)
            return recipeItem
        }))
        
        items = allItems
        
        print("loadRecipes...return")
        return
    }
    
#else
    
    /// Load and wrap your recipes in order
    func loadRecipes(from url: URL? = nil) {
        //        FetchCache.shared.load()
        //        let recipes =
        print("Asdfasdfsdf")
        let recipes = Recipe.allFromJSON(using: .good) // Network call
        self.items.append(contentsOf: recipes.map ({ recipe in
            RecipeItem(recipe: recipe)
        }))
        //        self.items = recipes.map ({ recipe in
        //            RecipeItem(recipe: recipe)
        //        })
        print("Asdfasdfsdf...return")
        return
    }
    
#endif
    
}



struct SearchViewModel: Identifiable {
    var id: String { text }
    var text: String
}
