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
    @Published var searchModel: SearchViewModel?

    @ObservedObject var recipeStore: RecipeStore
    private let memoryStore: RecipeMemoryStoreProtocol
    private let filterStrategy: RecipeFilterStrategy
    private var cancellables = Set<AnyCancellable>()
    let filterTrigger = PassthroughSubject<Void, Never>()
    
    // MARK: - Init
    
    init(memoryStore: RecipeMemoryStoreProtocol, recipeStore: RecipeStore, filterStrategy: RecipeFilterStrategy) {
        self.memoryStore = memoryStore
        self.recipeStore = recipeStore
        self.filterStrategy = filterStrategy
        
//        filterTrigger
//            .flatMap { _ in
//                print("filtertriggered")
//                return Publishers.CombineLatest3(
//                    recipeStore.itemsPublisher,
//                    self.$selectedCuisine,
//                    self.$searchQuery
//                )
//            }
//            .map { items, cuisine, query in
//                filterStrategy.filter(items, cuisine: cuisine, query: query)
//            }
//            .receive(on: RunLoop.main)
//            .assign(to: &$items)
        
        Publishers.CombineLatest3(
            recipeStore.itemsPublisher,
            $selectedCuisine.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
            $searchQuery.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        )
        .map { items, cuisine, query in
            filterStrategy.filter(items, cuisine: cuisine, query: query)
        }
        .assign(to: &$items)
    }
    
    // MARK: - Public API
    
    /// Start FetchCache using pathComponent.
    /// Succeeds unless any error occurs in the cache initialization procees. throws a verbose error if fails.
    /// the error
    func startCache(path: String) throws {
        print("Starting cache at path: \(path)")
        try FetchCache.shared.openCacheDirectoryWithPath(path: path)
    }
    
    /// resets fields to reload again
    func reload() async -> Bool {
        self.items.removeAll()
        self.searchQuery = ""
        self.selectedCuisine = nil
        self.searchModel = nil
        
        return await loadRecipes()
    }
    
    func addNote(_ text: String, for recipeUUID: UUID) {
        guard memoryStore.isFavorite(for: recipeUUID) else { return }
        if let note = memoryStore.addNote(text, for: recipeUUID) {
            recipeStore.addNote(note, for: recipeUUID)
        }
    }
    
    var cusineCategories: [String] {
        var categories = Set<String>()
        for item in items {
            categories.insert(item.cuisine)
        }
        return Array(categories)
    }
}

struct SearchViewModel: Identifiable {
    var id: String { text }
    var text: String
    var categories: [String] = []
}

@MainActor
class RecipeStore: ObservableObject {
    @Published private(set) var allItems: [RecipeItem] = []
    
    var itemsPublisher: AnyPublisher<[RecipeItem], Never> {
        $allItems.eraseToAnyPublisher()
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = allItems.firstIndex(where: { $0.id == id }) else { return }
        allItems[index].isFavorite.toggle()
        allItems = allItems // triggers Combine update
    }

    func loadRecipes(recipes: [RecipeItem]) {
        allItems = recipes
    }
    
    func deleteNotes(for id: UUID) {
        guard let index = allItems.firstIndex(where: { $0.id == id }) else { return }
        allItems[index].notes.removeAll()
    }
    
    func addNote(_ note: RecipeNote, for id: UUID) {
        guard let index = allItems.firstIndex(where: { $0.id == id }) else { return }
        allItems[index].notes.append(note)
    }
}

@MainActor
protocol RecipeDataConsumer {
    var items: [RecipeItem] { get }
    var recipeStore: RecipeStore { get }
    func toggleFavorite(recipeUUID: UUID)
    func loadRecipes(from url: URL?) async -> Bool
}

extension RecipesViewModel: RecipeDataConsumer {
    
    
#if DEBUG
    
    /// Load recipes and update listeners through `RecipeStore`
    /// Returns true if parsing succeeded, false otherwise.
    func loadRecipes(from url: URL? = nil) async -> Bool {
        do {
            let recipes = try await Recipe.allFromJSON(using: .good) // Network call
            recipeStore.loadRecipes(recipes: recipes.map ({ recipe in
                var recipeItem = RecipeItem(recipe: recipe)
                recipeItem.isFavorite = memoryStore.isFavorite(for: recipe.id)
                recipeItem.notes = memoryStore.notes(for: recipe.id)
                return recipeItem
            }))
            filterSend()
        } catch is RecipeDecodeError {
            return false
        }
        return true
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
    
    
    func toggleFavorite(recipeUUID: UUID) {
        print("is favorite beggining: \(memoryStore.isFavorite(for: recipeUUID))")
        memoryStore.toggleFavorite(recipeUUID: recipeUUID)
        recipeStore.toggleFavorite(recipeUUID)
        if !memoryStore.isFavorite(for: recipeUUID) {
            print("it's not favorite")
            memoryStore.deleteNotes(for: recipeUUID)
            recipeStore.deleteNotes(for: recipeUUID)
        }
    }
}

extension RecipesViewModel: Filterable {
    func filterSend() {
        filterTrigger.send()
    }
}

@MainActor
protocol RecipeFilterStrategy {
    func filter(_ items: [RecipeItem], cuisine: String?, query: String?) -> [RecipeItem]
}

struct AllRecipesFilter: RecipeFilterStrategy {
    func filter(_ items: [RecipeItem], cuisine: String?, query: String?) -> [RecipeItem] {
        var filtered = items
        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if let query = query, !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered
    }
}


struct FavoriteRecipesFilter: RecipeFilterStrategy {
    func filter(_ items: [RecipeItem], cuisine: String?, query: String?) -> [RecipeItem] {
        var filtered = items.filter({ $0.isFavorite })
        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if let query = query, !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered
    }
}
    
protocol Filterable {
    func filterSend()
}
