//
//  RecipeMemoryDataSourceTests.swift
//  UIDemoTests
//
//  Created by Arturo Aguilar on 7/15/25.
//
import XCTest
@testable import UIDemo
import SwiftUICore

@MainActor
final class RecipeMemoryDataSourceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var key: String!
    private var sut: RecipeMemoryDataSource!

    override func setUp() {
        super.setUp()
        // Use a unique suite for each test
        suiteName = "RecipeMemoryTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        key = "TestKey"
        sut = RecipeMemoryDataSource(key: key, defaults: defaults)
    }

    override func tearDown() {
        // Clean up the suite storage
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        sut = nil
        super.tearDown()
    }

    func test_initialMemoriesEmpty() {
        // On a fresh data source, memories should be empty
        XCTAssertTrue(sut.memories.isEmpty)
    }

    func test_load_preseededData() {
        // Seed the defaults with a saved memory
        let id = UUID()
        let memory = RecipeMemory(isFavorite: true, notes: [])
        let dict = [id: memory]
        let data = try! JSONEncoder().encode(dict)
        defaults.set(data, forKey: key)

        // Reload from defaults
        sut.load()
        XCTAssertEqual(sut.memories[id]?.isFavorite, true)
    }

    func test_getMemory_unknownUUID_returnsDefault() {
        let unknown = UUID()
        let result = sut.getMemory(for: unknown)
        XCTAssertFalse(result.isFavorite)
        XCTAssertTrue(result.notes.isEmpty)
    }

    func test_setFavorite_and_isFavorite() {
        let id = UUID()
        XCTAssertFalse(sut.isFavorite(for: id))

        sut.setFavorite(true, for: id)
        XCTAssertTrue(sut.isFavorite(for: id))
        XCTAssertEqual(sut.memories[id]?.isFavorite, true)

        sut.setFavorite(false, for: id)
        XCTAssertFalse(sut.isFavorite(for: id))
    }

    func test_toggleFavorite_flipsFlag() {
        let id = UUID()

        sut.toggleFavorite(recipeUUID: id)
        XCTAssertTrue(sut.isFavorite(for: id))

        sut.toggleFavorite(recipeUUID: id)
        XCTAssertFalse(sut.isFavorite(for: id))
    }

    func test_addNote_onlyIfFavorite() {
        let id = UUID()
        // Not favorite = no notes
        sut.addNote("note", for: id)
        XCTAssertTrue(sut.notes(for: id).isEmpty)

        // Mark favorite and add note
        sut.setFavorite(true, for: id)
        sut.addNote("note", for: id)
        XCTAssertEqual(sut.notes(for: id).count, 1)
        XCTAssertEqual(sut.notes(for: id).first?.text, "note")
    }

    func test_deleteNotes_keepsFavoriteFlag() {
        let id = UUID()
        sut.setFavorite(true, for: id)
        sut.addNote("a", for: id)
        XCTAssertFalse(sut.notes(for: id).isEmpty)

        sut.deleteNotes(for: id)
        XCTAssertTrue(sut.notes(for: id).isEmpty)
        XCTAssertTrue(sut.isFavorite(for: id))
    }

    func test_save_and_load_roundTrip() {
        let id = UUID()
        sut.setFavorite(true, for: id)
        sut.addNote("persist", for: id)
        sut.save()

        // New instance should pick up saved state
        let reloaded = RecipeMemoryDataSource(key: key, defaults: defaults)
        XCTAssertTrue(reloaded.isFavorite(for: id))
        XCTAssertEqual(reloaded.notes(for: id).map(\.text), ["persist"])
    }
}
