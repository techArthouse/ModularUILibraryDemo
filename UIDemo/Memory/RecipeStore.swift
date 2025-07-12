//
//  RecipeStore.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/12/25.
//

import SwiftUI
import Combine

/// RecipeStore is a domain data service, not just a data loader. It’s the central place to query recipe identity, status, and cache-insulated data.
@MainActor
class RecipeStore: ObservableObject, RecipeService {
    @Published private(set) var allItems: [Recipe] = []
    var memoryStore: RecipeMemoryStoreProtocol // should i use protocol for testing?
    @Published private(set) var fetchCache: ImageCache
    
    init(memoryStore: RecipeMemoryStoreProtocol, fetchCache: ImageCache) {
        self.memoryStore = memoryStore
        self.fetchCache = fetchCache
    }
    var itemsPublisher: AnyPublisher<[Recipe], Never> {
        $allItems.eraseToAnyPublisher()
    }
    
    //    func toggleFavorite(_ id: UUID) {
    //        let toggledFavoriteValue = !self.isFavorite(for: id) // NOT(`!`) toggles current value.
    //        memoryStore.setFavorite(toggledFavoriteValue, for: id)
    //    }
    
    func loadRecipes(recipes: [Recipe]) {
        print("we loaded recipe with id: \(recipes.first!.id)")
        allItems = recipes
    }
    
    // MARK: - Recipe Acessors
    func title(for id: UUID) -> String {
        guard let title = allItems.first(where: { $0.id == id })?.name else { return "" }
        return title
    }
    func description(for id: UUID) -> String {
        guard let title = allItems.first(where: { $0.id == id })?.cuisine else { return "" }
        return title
    }
    
    func isNotValid(for id: UUID) -> Bool {
        guard let isInvalid = allItems.first(where: { $0.id == id })?.isNotValid else { return false }
        return isInvalid
    }
    func isFavorite(for id: UUID) -> Bool          { memoryStore.isFavorite(for: id) }
    func toggleFavorite(_ id: UUID)                { memoryStore.toggleFavorite(recipeUUID: id) }
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) { memoryStore.setFavorite(favorite, for: recipeUUID) }
    func notes(for id: UUID) -> [RecipeNote]       { memoryStore.notes(for: id) }
    func addNote(_ text: String, for id: UUID)     { memoryStore.addNote(text, for: id) }
    func deleteNotes(for id: UUID) {
        memoryStore.deleteNotes(for: id)
    }
    func smallImageURL(for id: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == id })?.smallImageURL else { return nil }
        return url
    }
    func largeImageURL(for recipeId: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == recipeId })?.largeImageURL else { return nil }
        return url
    }
    
    func sourceWebsiteURL(for recipeId: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == recipeId })?.sourceWebsiteURL else { return nil }
        return url
    }
    
    func youtubeVideoURL(for recipeId: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == recipeId })?.youtubeVideoURL else { return nil }
        return url
    }
    func startCache(path: String) throws(FetchCacheError) {
        try fetchCache.openCacheDirectoryWithPath(path: path)
    }
    func refresh() async {
        await fetchCache.refresh()
    }
}
