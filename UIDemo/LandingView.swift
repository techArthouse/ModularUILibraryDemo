//
//  LandingView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//


import SwiftUI
import ModularUILibrary

// MARK: - Navigation State

enum Tab: Hashable {
    case home, favorites, profile
}

enum Route: Hashable {
    case landing
    case recipes
    case recipeDetail(Recipe)
}

// MARK: - Landing Page

struct LandingView: View {
    let onViewRecipes: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Fetch Recipes")
                .font(.largeTitle).bold()
            Spacer()
            Button(action: onViewRecipes) {
                Text("View Recipes")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .padding()
    }
}

@MainActor
class RecipesViewModel: ObservableObject {
    @Published var items: [RecipeItem] = []
    @Published var currentPageURL: URL? = nil

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
            RecipeItem(recipe: recipe)
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
    
    func getRecipeImage(for recipeItem: Binding<RecipeItem>) async  {
//        guard let url = recipeItem.smallImageURL else { return }
        recipeItem.wrappedValue.image = Image(systemName: "heart") // await FetchCache.shared.getImageFor(url: url)
    }

    /// Drop both image memory & disk caches, and clear each item’s image
//    func refreshAll() {
//        FetchCache.shared.refresh()
//        for item in items {
//            item.image = Image(systemName: "heart")
//        }
//    }
}


// MARK: - Recipe Detail View


struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        VStack {
            Text(recipe.name)
                .font(.title)
            if let url = recipe.youtubeVideoURL {
                VideoPlayerView(url: url)
                    .frame(height: 200)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Details")
    }
}


/// A little view-model for each recipe row
@MainActor
class RecipeItem: ObservableObject, Identifiable {
    @Published var recipe: Recipe
    @Published var image: Image?
    let id: String

    init(recipe: Recipe) {
        self.recipe = recipe
        self.id = recipe.uuidString
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
    
//    var daImage: Image {
//        self.image ?? Image(systemName: "heart.circle")
//    }
}

// MARK: - Root ContentView


// MARK: - Utilities (Proxy for scroll)

// Simple proxy to hold reference to the ScrollViewReader proxy
final class ScrollViewProxy {
    static let shared = ScrollViewProxy()
    var proxy: ScrollViewProxy? = nil
    func scrollToTop() {
        // implement scrolling logic here
    }
}

// MARK: - Video Player Placeholder

struct VideoPlayerView: View {
    let url: URL
    var body: some View {
        Text("Video player for: \(url.absoluteString)")
    }
}
