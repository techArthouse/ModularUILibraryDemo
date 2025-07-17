//
//  RecipeDataServiceTests.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/14/25.
//

import XCTest
import SwiftUI
@testable import UIDemo

@MainActor
final class RecipeDataServiceTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var memory: RecipeMemoryDataSource!
    private var cache: FakeImageCache!
    private var sut: RecipeDataService!
    private var sampleId: UUID!
    private var sample: Recipe!

    override func setUp() {
        super.setUp()
        // 1) Defaults
        suiteName = "RecipeDataServiceTests.\(UUID())"
        defaults = UserDefaults(suiteName: suiteName)!
        memory = RecipeMemoryDataSource(key: "TestKey", defaults: defaults)

        // 2) Fake cache
        cache = FakeImageCache()

        // 3) System Under Test
        sut = RecipeDataService(memoryStore: memory, fetchCache: cache)

        // 4) Sample recipe
        sampleId = UUID()
        sample = Recipe(id: sampleId, name: "TestName", cuisine: "TestCuisine")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        memory = nil
        cache = nil
        sut = nil
        super.tearDown()
    }

    func test_metadata_and_url_accessors() {
        sut.setRecipes(recipes: [sample])
        XCTAssertEqual(sut.title(for: sampleId), "TestName")
        XCTAssertEqual(sut.description(for: sampleId), "TestCuisine")
        XCTAssertFalse(sut.isNotValid(for: sampleId))

        // URLs come straight off the Recipe model
        XCTAssertNil(sut.smallImageURL(for: sampleId))
        XCTAssertNil(sut.largeImageURL(for: sampleId))
        XCTAssertNil(sut.sourceWebsiteURL(for: sampleId))
        XCTAssertNil(sut.youtubeVideoURL(for: sampleId))
    }

    func test_favorites_and_notes_lifecycle() {
        sut.setRecipes(recipes: [sample])

        // Initially not favorite
        XCTAssertFalse(sut.isFavorite(for: sampleId))
        XCTAssertTrue(sut.notes(for: sampleId).isEmpty)

        // Mark favorite
        sut.setFavorite(true, for: sampleId)
        XCTAssertTrue(sut.isFavorite(for: sampleId))

        // Add a note
        sut.addNote("Hello", for: sampleId)
        XCTAssertEqual(sut.notes(for: sampleId).count, 1)

        // Toggle off
        sut.toggleFavorite(sampleId)
        XCTAssertFalse(sut.isFavorite(for: sampleId))
    }

    func test_refreshImageCache() async {
        await sut.refreshImageCache()
        XCTAssertTrue(cache.didRefresh)
    }
}
