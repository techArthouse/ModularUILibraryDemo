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
    @StateObject private var fetchCache = FetchCache(path: cachePath)

    /// Central source of truth for recipe data.
    @StateObject private var recipeStore: RecipeStore

    /// Initializes the application, setting up the shared data sources:
    /// - A memory-backed data source for recipes.
    /// - A single shared fetch cache for image loading.
    /// - A recipe store that coordinates between memory and network.
    init() {
        let memoryStore = RecipeMemoryDataSource.shared
        let cache = FetchCache(path: Self.cachePath)
        let store = RecipeStore(memoryStore: memoryStore, fetchCache: cache)
        _recipeStore = StateObject(wrappedValue: store)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(recipeStore: recipeStore)
                .environmentObject(themeManager)
        }
    }
}
