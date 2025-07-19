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
class FakeRecipeDataService: RecipeDataServiceProtocol {
    @Published var allItems: [Recipe] = []
    @Published var imageCache: any ImageCacheProtocol = FakeImageCache()
    var itemsPublisher: AnyPublisher<[Recipe], Never> { $allItems.eraseToAnyPublisher() }
    func setRecipes(recipes: [Recipe]) {
        allItems = recipes }

    // metadata stubs
    func title(for id: UUID) -> String { allItems.first { $0.id == id }?.name ?? "" }
    func description(for id: UUID) -> String { allItems.first { $0.id == id }?.cuisine ?? "" }
    func isRecipeValid(for id: UUID) -> Bool {
        guard let isInvalid = allItems.first(where: { $0.id == id })?.isValid else { return false }
        return isInvalid
    }

    // favorites & notes stub via in-memory
    private var memory = RecipeMemoryDataSource(key: "Fake", defaults: UserDefaults(suiteName: "Fake")!)
    func isFavorite(for id: UUID) -> Bool { memory.isFavorite(for: id) }
    func toggleFavorite(_ id: UUID) { memory.toggleFavorite(recipeUUID: id) }
    func setFavorite(_ fav: Bool, for id: UUID) { memory.setFavorite(fav, for: id) }
    func notes(for id: UUID) -> [RecipeNote] { memory.notes(for: id) }
    func addNote(_ text: String, for id: UUID) { memory.addNote(text, for: id) }
    func deleteNotes(for id: UUID) { memory.deleteNotes(for: id) }

    // URLs
    func smallImageURL(for id: UUID) -> URL? { nil }
    func largeImageURL(for id: UUID) -> URL? { nil }
    func sourceWebsiteURL(for id: UUID) -> URL? { nil }
    func youtubeVideoURL(for id: UUID) -> URL? { nil }

    // image cache
    private(set) var didRefresh = false
    func refreshImageCache() async { didRefresh = true }
}
