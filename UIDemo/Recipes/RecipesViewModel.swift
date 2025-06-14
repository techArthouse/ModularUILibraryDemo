//
//  RecipesViewModel.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

@MainActor
class RecipesViewModel: ObservableObject {
    @Published var items: [RecipeItem] = []
    @Published var currentPageURL: URL? = nil
//    @EnvironmentObject var dataSource: RecipeDataSource // = RecipeDataSource.shared
    
    // We want the vm to always instantiate to not break consumers, but we should also allow for default no action and later load based on new urlString
    init(hostURLString: String? = nil) {
        guard let urlString = hostURLString, let _ = URL(string: urlString) else { // here for dependency incject directory root path
            return
        }
        //        // if user suplied valid string for a URL then let's load it
        //        FetchCache.shared.loadIfNeeded()
    }
    
    /// Start FetchCache using pathComponent.
    /// Succeeds unless any error occurs in the cache initialization procees. throws a verbose error if fails.
    /// the error
    func startCache(path: String) throws(FetchCacheError) {
        try FetchCache.shared.openCacheDirectoryWithPath(path: path)
    }
    
#if DEBUG
    
    /// Load and wrap your recipes in order
    func loadRecipes(from url: URL? = nil) async {
        let recipes = await Recipe.allFromJSON(using: .good) // Network call
        self.items.append(contentsOf: recipes.map ({ recipe in
             return RecipeItem(recipe: recipe)
//            if let url = recipe.sourceWebsiteURL {
//                recipeItem.isFavorite = true // dataSource.getMemory(for: url).isFavorite
//            }
//            return recipeItem
        }))
        
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
