//
//  RecipeFilterStrategy.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/14/25.
//

import SwiftUI

@MainActor
protocol RecipeFilterStrategy {
    func filter(_ items: [Recipe], cuisine: String?, query: String?) -> [UUID]
}

extension RecipeFilterStrategy {
    var isFavorite: Bool {
        (self as? FavoriteRecipesFilter) != nil
    }
}

struct AllRecipesFilter: RecipeFilterStrategy {
    
    func filter(_ items: [Recipe], cuisine: String?, query: String?) -> [UUID] {
        var filtered = items
        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if let query = query, !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered.map({$0.id})
    }
}


struct FavoriteRecipesFilter: RecipeFilterStrategy {
    func filter(_ items: [Recipe], cuisine: String?, query: String?) -> [UUID] {
        var filtered = items // .filter({ $0.isFavorite })
        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if let query = query, !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered.map({$0.id})
    }
}
