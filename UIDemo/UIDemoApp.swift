//
//  UIDemoApp.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 2/26/24.
//

import SwiftUI
import ModularUILibrary

/// The entry point for the UIDemo application.
/// Responsible for initializing global singletons such as the thememanager which comes from ui library,
/// image fetch cache, and recipe store, and injecting them into the root view.
@main
struct UIDemoApp: App {
    /// Manages application-wide theming.
    @StateObject var themeManager: ThemeManager = ThemeManager()

    /// Path for storing and retrieving cached images.
    /// Uses a different cache when running in DEBUG mode.
    private static var cachePath: String {
    #if DEBUG
        return "DevelopmentFetchImageCache"
    #else
        return "FetchImageCache"
    #endif
    }

    /// Shared image fetch cache for the entire app.
//    @StateObject private var fetchCache = FetchCache(path: cachePath)

    /// Central source of truth for recipe data.
    @StateObject private var recipeStore: RecipeDataService
    private let networkService: NetworkService

    /// Initializes the application, setting up the shared data sources:
    /// - A memory-backed data source for recipes.
    /// - A single shared fetch cache for image loading.
    /// - A recipe store that coordinates between memory and network.
    init() {
        let networkService = NetworkService()
        let memoryStore = RecipeMemoryDataSource()
        let cache = CustomAsyncImageCache(path: Self.cachePath, networkService: networkService)
        let store = RecipeDataService(memoryStore: memoryStore, fetchCache: cache)
        _recipeStore = StateObject(wrappedValue: store)
        self.networkService = networkService
    }
    
    
    // NOTE: - Below we check for a flag that xcode sets during testing. Figuring this out was
    // necessary as unit tests launched uiviews during one such test `RecipesViewModelTests`. The alternative to
    // this is to move modular code to it's own package. At this time there's no reason to do that,
    // but as the library grows i might. 
    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                    EmptyView()
                } else {
                    ContentView(
                        makeHomeVM: {
                            RecipesViewModel(
                                recipeStore: recipeStore,
                                filterStrategy: AllRecipesFilter(),
                                networkService: networkService)
                        },
                        makeFavoritesVM: {
                            RecipesViewModel(
                                recipeStore: recipeStore,
                                filterStrategy: FavoriteRecipesFilter(),
                                networkService: networkService)
                        },
                        makeDiscoveryVM: { DiscoverViewModel(recipeStore: recipeStore) }
                        
                    )
                    .environmentObject(themeManager)
                }
            }
        }
    }
}
