//
//  RecipeItem.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

/// A little view-model for each recipe row
@MainActor
class RecipeItem: ObservableObject, Identifiable {
    
    @Published var recipe: Recipe
    @Published var image: Image?
    @Published var isFavorite: Bool = false
    @Published var notes: [RecipeNote] = []
    @Published var markedForRemoval = false
    let id: UUID

    init(recipe: Recipe) {
        self.recipe = recipe
        self.id = recipe.id
    }
}

// MARK: - Convenience accessors for recipe data.

extension RecipeItem {
    var uuidString: String {
        recipe.id.uuidString
    }
    var name: String {
        recipe.name
    }
    
    var cuisine: String {
        recipe.cuisine
    }
    
    var smallImageURL: URL? {
        recipe.smallImageURL
    }
    
    var largeImageURL: URL? {
        recipe.largeImageURL
    }
    
    var sourceURL: URL? {
        recipe.sourceWebsiteURL
    }
    
    var videoURL: URL? {
        recipe.youtubeVideoURL
    }
}
