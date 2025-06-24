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
//    init(cache: RecipeCacheProtocol, memoryStore: RecipeMemoryStoreProtocol) {
//        self.cache = cache
//        self.memoryStore = memoryStore
//        
//        $selectedCuisine
//            .sink { [weak self] cuisine in
//                guard let strongSelf = self else { return }
//                print("Selected cuisine: \(cuisine ?? "nil")")
//                if let cuisine = cuisine {
//                    strongSelf.applyFilters(query: strongSelf.searchQuery, cuisine: cuisine)
//                } else {
//                    strongSelf.items = strongSelf.allItems
//                }
//            }
//            .store(in: &cancellables)
//    }
    
    init(cache: RecipeCacheProtocol, memoryStore: RecipeMemoryStoreProtocol) {
        self.cache = cache
        self.memoryStore = memoryStore

        Publishers.CombineLatest(
            $searchQuery.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
            $selectedCuisine
        )
        .sink { [weak self] query, cuisine in
            self?.applyFilters(query: query, cuisine: cuisine)
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Filter Logic
    private func applyFilters(query: String, cuisine: String?) {
        var filtered = allItems

        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }

        items = filtered
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
        
        print("syncRecipeMemoryStore: \(memoryStore.isFavorite(for: item.id))")
        item.isFavorite = memoryStore.isFavorite(for: item.id)
        item.notes = memoryStore.notes(for: item.id)
    }
    
    func isFavorite(recipeUUID: UUID) -> Bool {
        memoryStore.isFavorite(for: recipeUUID)
    }
    
    func toggleFavorite(recipeUUID: UUID) {
        print("is favorite beggining: \(memoryStore.isFavorite(for: recipeUUID))")
        memoryStore.toggleFavorite(recipeUUID: recipeUUID)
        if !memoryStore.isFavorite(for: recipeUUID) {
            print("it's not favorite")
            memoryStore.deleteNotes(for: recipeUUID)
        }
        
            
        if var item = items.first(where: { $0.id == recipeUUID }) {
            print("is favorite beggining end: \(memoryStore.isFavorite(for: recipeUUID))")
            syncRecipeMemoryStore(item: item)
//            item.isFavorite = memoryStore.isFavorite(for: recipeUUID)
//            allItems.first(where: { $0.id == recipeUUID})?.isFavorite = memoryStore.isFavorite(for: recipeUUID)
//            items = allItems
        }
    }
    
    func addNote(_ text: String, for recipeUUID: UUID) {
        memoryStore.addNote(text, for: recipeUUID)
        if let item = items.first(where: { $0.id == recipeUUID }) {
            item.notes = memoryStore.notes(for: recipeUUID)
        }
    }
    
    var cusineCategories: [String] {
        var categories = Set<String>()
        for item in allItems {
            categories.insert(item.cuisine)
        }
        return Array(categories)
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
    var categories: [String] = []
}
