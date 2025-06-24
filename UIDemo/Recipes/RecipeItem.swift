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
    let id: UUID

    init(recipe: Recipe) {
        self.recipe = recipe
        self.id = recipe.id
    }

//    /// Call once (e.g. in .task) to lazily fill in the image
//    func loadImage() async {
//        // early exit if already loaded
////        guard image == nil else { return }
//
//        // 1) missing URL → show “not found”
//        guard let url = recipe.largeImageURL else {
////            self.image = theme
////              .imageAssetManager
////              .getImage(imageIdentifier: .preset(.imageNotFound))
//            return
//        }
//
//        // 2) fetch via your shared cache
//        let fetchedImage = await FetchCache.shared.getImageFor(url: url) // {
//        self.image = fetchedImage
////        } else {
//////            self.image = theme
//////              .imageAssetManager
//////              .getImage(imageIdentifier: .preset(.imageNotFound))
////        }
//    }
}

// MARK: - Convenience accessors for recipe data.

extension RecipeItem {
    var uuidString: String {
        recipe.uuidString
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
    
    var sourceURL: URL? {
        recipe.sourceWebsiteURL
    }
    
    var videoURL: URL? {
        recipe.youtubeVideoURL
    }
    
//    var daImage: Image {
//        self.image ?? Image(systemName: "heart.circle")
//    }
}
