//
//  RecipeDataService.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/12/25.
//

import SwiftUI
import Combine

/// RecipeStore is a domain data service, not just a data loader. It’s the central place to query recipe identity, status, and cached data.
@MainActor
class RecipeDataService: RecipeDataServiceProtocol {
    @Published private(set) var allItems: [Recipe] = []
    @Published var memoryDataSource: RecipeMemoryDataSourceProtocol // should i use protocol for testing?
    @Published private(set) var imageCache: ImageCacheProtocol
    
    init(memoryStore: any RecipeMemoryDataSourceProtocol, fetchCache: ImageCacheProtocol) {
        self.memoryDataSource = memoryStore
        self.imageCache = fetchCache
    }
    var itemsPublisher: AnyPublisher<[Recipe], Never> {
        $allItems.eraseToAnyPublisher()
    }
    
    func setRecipes(recipes: [Recipe]) {
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
    
    func isFavorite(for id: UUID) -> Bool {
        return memoryDataSource.isFavorite(for: id)
    }
    
    func toggleFavorite(_ id: UUID) {
        memoryDataSource.toggleFavorite(recipeUUID: id)
    }
    
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) {
        memoryDataSource.setFavorite(favorite, for: recipeUUID)
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
    
    func refreshImageCache() async {
        await imageCache.refresh()
    }
}
