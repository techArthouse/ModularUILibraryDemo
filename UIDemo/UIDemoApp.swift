//
//  UIDemoApp.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 2/26/24.
//

import SwiftUI
import ModularUILibrary

@main
struct UIDemoApp: App {
    @StateObject var themeManager: ThemeManager = ThemeManager()
    private static var cachePath: String {
#if DEBUG
        return "DevelopmentFetchImageCache"
#else
        return "FetchImageCache"
#endif
    }

    // 2️⃣ Construct your single FetchCache instance once
    @StateObject private var fetchCache = FetchCache(path: cachePath)
    @StateObject private var recipeStore: RecipeStore

    init() {
        let memoryStore = RecipeMemoryDataSource.shared
        // re-use the same cachePath for both fetchCache and recipeStore
        let cache = FetchCache(path: Self.cachePath)
        let store = RecipeStore(memoryStore: memoryStore, fetchCache: cache)
        _recipeStore = StateObject(wrappedValue: store)
    }
    
    var body: some Scene {
        WindowGroup {
            
    #if DEBUG
            ContentView(recipeStore: recipeStore)
                .environmentObject(themeManager)
    #else
            ContentView(recipeStore: recipeStore)
                .environmentObject(themeManager)
    #endif
                
        }
    }
}
