//
//  RecipeDataService.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/12/25.
//

import SwiftUI
import Combine

/// RecipeStore is a domain data service, not just a data loader. It’s the central place to query recipe identity, status, and cached data.
/// It is the source of truth for `Recipe` models shared across VM's.
@MainActor
final class RecipeDataService: RecipeDataServiceProtocol {
    @Published private(set) var allItems: [Recipe] = [] // Models decoded from network
    @Published private(set) var memoryDataSource: RecipeMemoryDataSourceProtocol // Stores RecipMemory data
    @Published private(set) var imageCache: ImageCacheProtocol
    
    init(memoryStore: any RecipeMemoryDataSourceProtocol, fetchCache: ImageCacheProtocol) {
        self.memoryDataSource = memoryStore
        self.imageCache = fetchCache
    }
    
    // Used to subscribe to updates to recipe array
    var itemsPublisher: AnyPublisher<[Recipe], Never> {
        $allItems.eraseToAnyPublisher()
    }
    
    func setRecipes(recipes: [Recipe]) {
        allItems = recipes
    }
    
    // MARK: - Recipe Acessors
    func title(for id: UUID) -> String {
        itemIfexists(for: id)?.name ?? ""
    }
    
    func description(for id: UUID) -> String {
        itemIfexists(for: id)?.cuisine ?? ""
    }
    
    func smallImageURL(for id: UUID) -> URL? {
        itemIfexists(for: id)?.smallImageURL
    }
    
    func largeImageURL(for id: UUID) -> URL? {
        itemIfexists(for: id)?.largeImageURL
    }
    
    func sourceWebsiteURL(for id: UUID) -> URL? {
        itemIfexists(for: id)?.sourceWebsiteURL
    }
    
    func youtubeVideoURL(for id: UUID) -> URL? {
        itemIfexists(for: id)?.youtubeVideoURL
    }
    
    func isNotValid(for id: UUID) -> Bool {
        itemIfexists(for: id)?.isNotValid ?? false
    }
    
    // MARK: - Memory Accessors
    func isFavorite(for id: UUID) -> Bool {
        memoryDataSource.isFavorite(for: id)
    }
    
    func toggleFavorite(_ id: UUID) {
        memoryDataSource.toggleFavorite(recipeUUID: id)
    }
    
    func setFavorite(_ favorite: Bool, for id: UUID) {
        memoryDataSource.setFavorite(favorite, for: id)
    }
    
    func notes(for id: UUID) -> [RecipeNote] {
        memoryDataSource.notes(for: id)
    }
    
    func addNote(_ text: String, for id: UUID) {
        memoryDataSource.addNote(text, for: id)
    }
    
    func deleteNotes(for id: UUID) {
        memoryDataSource.deleteNotes(for: id)
    }
    
    func refreshImageCache() async {
        await imageCache.refresh()
    }
    
    // MARK: - Helpers
    private func itemIfexists(for id: UUID) -> Recipe? {
        allItems.first(where: { $0.id == id })
    }
}
