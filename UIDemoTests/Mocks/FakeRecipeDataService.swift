//
//  FakeRecipeService.swift
//  UIDemoTests
//
//  Created by Arturo Aguilar on 7/12/25.
//
import XCTest
import Combine
@testable import UIDemo

/// A fake RecipeStore that lets us publish custom recipe arrays and observe how the view model reacts.
@MainActor
private class FakeRecipeDataService: RecipeDataServiceProtocol {
    var imageCache: any ImageCacheProtocol = FakeImageCache()
    
    func setRecipes(recipes: [Recipe]) {
        self.allItems = recipes
    }
    
    @Published var allItems: [Recipe] = []
    var itemsPublisher: AnyPublisher<[Recipe], Never> { $allItems.eraseToAnyPublisher() }

    // MARK: – Metadata
    func title(for id: UUID) -> String {
      allItems.first(where: { $0.id == id })?.name ?? ""
    }
    func description(for id: UUID) -> String {
      allItems.first(where: { $0.id == id })?.cuisine ?? ""
    }
    func isNotValid(for id: UUID) -> Bool {
      allItems.first(where: { $0.id == id })?.isNotValid ?? false
    }

    private var memory: RecipeMemoryDataSource = RecipeMemoryDataSource(key: "Fake", defaults: UserDefaults(suiteName: "Fake")!)
    func isFavorite(for id: UUID) -> Bool                  { memory.isFavorite(for: id) }
    func toggleFavorite(_ id: UUID)                        { memory.toggleFavorite(recipeUUID: id) }
    func setFavorite(_ fav: Bool, for id: UUID)            { memory.setFavorite(fav, for: id) }
    func notes(for id: UUID) -> [RecipeNote]               { memory.notes(for: id) }
    func addNote(_ text: String, for id: UUID)             { memory.addNote(text, for: id) }
    func deleteNotes(for id: UUID)                         { memory.deleteNotes(for: id) }

    // MARK: – URLs
    func smallImageURL(for id: UUID) -> URL?               { allItems.first(where: { $0.id == id })?.smallImageURL }
    func largeImageURL(for id: UUID) -> URL?               { allItems.first(where: { $0.id == id })?.largeImageURL }
    func sourceWebsiteURL(for id: UUID) -> URL?            { allItems.first(where: { $0.id == id })?.sourceWebsiteURL }
    func youtubeVideoURL(for id: UUID) -> URL?             { allItems.first(where: { $0.id == id })?.youtubeVideoURL }

    // MARK: – Image Cache
    private var _didRefresh = false
    func refreshImageCache() async {
      _didRefresh = true
    }
    var didRefresh: Bool { _didRefresh }
}
