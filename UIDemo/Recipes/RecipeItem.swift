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
    
//    @Published var recipe: Recipe
//    @Published var image: Image? // I thought to get rid of this because we have a image cache we can just use ```func getImageFor(url networkSourceURL: URL) async throws(FetchCacheError) -> Image```. but i don't want to make views depend on a global or injected fetchCache (the image cache) because i want that view component that shows an image to be reusable by other process. Can you remind me if having a published/observed image var is ideal?
//    @Published var isFavorite: Bool = false // is favorite is potentially toggled often enough, and it mutates memory but we have a datasource for it and we just need an id.
//    @Published var notes: [RecipeNote] = [] // we dont need this since we also have a datasource for that which is the same for isFavorite
    let id: UUID // essential and nonmutating
    @Published var selected: Bool // we've discussed this one.

    init(id: UUID, selected: Bool = true) {
        self.id = id
        self.selected = selected
    }
    
    init(_ recipe: Recipe) {
        self.id = recipe.id
        self.selected = true
    }
    
//    @Published var disabled: Bool = false
    
//    init(recipe: Recipe) {
//        self.recipe = recipe
//        self.id = recipe.id
//    }
}

// MARK: - Convenience accessors for recipe data.

//extension RecipeItem {
//    var uuidString: String {
//        recipe.id.uuidString
//    }
//    var name: String {
//        recipe.name
//    }
//    
//    var cuisine: String {
//        recipe.cuisine
//    }
//    
//    var isInvalid: Bool {
//        recipe.isInvalid
//    }
//    
//    var smallImageURL: URL? {
//        recipe.smallImageURL
//    }
//    
//    var largeImageURL: URL? {
//        recipe.largeImageURL
//    }
//    
//    var sourceURL: URL? {
//        recipe.sourceWebsiteURL
//    }
//    
//    var videoURL: URL? {
//        recipe.youtubeVideoURL
//    }
//}
