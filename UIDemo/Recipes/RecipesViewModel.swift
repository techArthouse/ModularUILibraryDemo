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
    
    private var allItems: [RecipeItem] = []
    private var cancellables = Set<AnyCancellable>()
//    var items: [RecipeItem] {
//            var result = allItems
//            
//            if !searchQuery.isEmpty {
//                result = result.filter {
//                    $0.name.localizedCaseInsensitiveContains(searchQuery)
//                }
//            }
//            
//            if let cuisine = selectedCuisine {
//                result = result.filter {
//                    $0.cuisine == cuisine
//                }
//            }
//            
//            return result
//        }
    
    @Published var currentPageURL: URL? = nil
//    @EnvironmentObject var dataSource: RecipeDataSource // = RecipeDataSource.shared
    
    // We want the vm to always instantiate to not break consumers, but we should also allow for default no action and later load based on new urlString
    init() {
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
        $selectedCuisine
            .sink { [weak self] cuisine in
                print("Selected cuisine: \(cuisine ?? "nil")")
                self?.applyFilters(query: self?.searchQuery ?? "", cuisine: cuisine)
            }
            .store(in: &cancellables)
        
    }
    
    
    private func applyFilters(query: String, cuisine: String?) {
//        guard cuisine != nil else {
//            assertionFailure("waht in the actual fak")
//            return
//        }
//        items = []
//        objectWillChange.send()
        var result = allItems
//        if !query.isEmpty {
//            result = result.filter { $0.name.localizedCaseInsensitiveContains(query) }
//        }
        if let cuisine = cuisine {
            print("oh yes hunny yes")
            items = result.filter {
                let include = $0.cuisine.lowercased() == cuisine.lowercased()
                print("\(include)")
                return include
            }
        }
//        items = result
//        objectWillChange.send()
//        searchModel = nil
    }
    
    /// Start FetchCache using pathComponent.
    /// Succeeds unless any error occurs in the cache initialization procees. throws a verbose error if fails.
    /// the error
    func startCache(path: String) throws(FetchCacheError) {
        print("its trying to start cache \(path)")
        try FetchCache.shared.openCacheDirectoryWithPath(path: path)
    }
    
#if DEBUG
    
    /// Load and wrap your recipes in order
    func loadRecipes(from url: URL? = nil) async {
        let recipes = await Recipe.allFromJSON(using: .good) // Network call
        self.allItems.append(contentsOf: recipes.map ({ recipe in
             return RecipeItem(recipe: recipe)
//            if let url = recipe.sourceWebsiteURL {
//                recipeItem.isFavorite = true // dataSource.getMemory(for: url).isFavorite
//            }
//            return recipeItem
        }))
        
        items = allItems
        
        print("Asdfasdfsdf...return")
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
