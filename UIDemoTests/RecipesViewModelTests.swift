//
//  RecipesViewModelTests.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/14/25.
//


import XCTest
import Combine
//import SwiftUI
@testable import UIDemo


// `RecipesViewModel` relies on combine for most updates to its view. Performance is smooth, however
// the test suite launches @main in the main target. Consequently, RecipesViewmodel has initialization
// overhead and takes longer than the time it would take to write and read inline in code. As such, this
// test suite isn't entirely isolated, so we delay assertions for read and write operations
// by 1-2 seconds to let the recipe array update as expected.
@MainActor
final class RecipesViewModelTests: XCTestCase {
    private var service: FakeRecipeDataService!
    private var vm: RecipesViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        service = FakeRecipeDataService()
        cancellables = []
        vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter())
    }

    override func tearDown() {
        vm = nil
        service = nil
        cancellables = nil
        super.tearDown()
    }

    func test_initialState() {
        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertEqual(vm.loadPhase, .idle)
        XCTAssertEqual(vm.cusineCategories, [])
    }


    func test_itemsPublisher_updatesItemsAndRespectsDefaultSelection() {
        let r1 = Recipe(id: UUID(), name: "One", cuisine: "A")
        let r2 = Recipe(id: UUID(), name: "Two", cuisine: "B")
        let expect = expectation(description: "Items updated")

        vm.$items
            .dropFirst()
            .first(where: { $0.map(\.id) == [r1.id, r2.id] })
            .sink { items in
                XCTAssertEqual(items.map(\.id), [r1.id, r2.id])
                XCTAssertTrue(items.allSatisfy { $0.selected })
                expect.fulfill()
            }
            .store(in: &cancellables)


        service.setRecipes(recipes: [r1, r2])
        wait(for: [expect], timeout: 1)
    }


    func test_filterByCuisine() {
        let italian = Recipe(id: UUID(), name: "Pizza", cuisine: "Italian")
        let tacos = Recipe(id: UUID(), name: "Taco", cuisine: "Mexican")

        let expectation = XCTestExpectation(description: "Wait for filter to apply")

        vm.$selectedCuisine
            .dropFirst()
            .sink { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let selectedIDs = self.vm.items.filter { $0.selected }.map { $0.id }
                    if selectedIDs == [italian.id] {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)

        service.setRecipes(recipes: [italian, tacos])
        vm.selectedCuisine = "Italian"

        wait(for: [expectation], timeout: 1.0)
    }

    func test_filterBySearchQuery() {
        let soup = Recipe(id: UUID(), name: "Tomato Soup", cuisine: "Global")
        let salad = Recipe(id: UUID(), name: "Green Salad", cuisine: "Global")
        service.setRecipes(recipes: [soup, salad])

        let expectation = XCTestExpectation(description: "Wait for filtered results")

        vm.$searchQuery
            .dropFirst()
            .sink { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let selectedIDs = self.vm.items.filter { $0.selected }.map { $0.id }
                    if selectedIDs == [soup.id] {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)

        vm.searchQuery = "Soup"

        wait(for: [expectation], timeout: 1.0)
    }

    func test_cuisineCategories_computedAfterFiltering() {
        let r1 = Recipe(id: UUID(), name: "A", cuisine: "One")
        let r2 = Recipe(id: UUID(), name: "B", cuisine: "Two")
        let r3 = Recipe(id: UUID(), name: "C", cuisine: "Two")
        service.setRecipes(recipes: [r1, r2, r3])

        let expectation = XCTestExpectation(description: "Wait for cuisine categories update")

        vm.$selectedCuisine
            .dropFirst()
            .sink { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let categories = Set(self.vm.cusineCategories)
                    if categories == Set(["One", "Two"]) {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)

        vm.selectedCuisine = nil

        wait(for: [expectation], timeout: 1.0)
    }

    func test_loadAll_transitionsToSuccess() {
        // subclass to override loadRecipes
        let testVM = TestableRecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter())
        var phases: [RecipesViewModel.LoadPhase] = []
        let exp = expectation(description: "phase change")

        testVM.$loadPhase
            .sink { phases.append($0) }
            .store(in: &cancellables)

        testVM.shouldThrow = false
        testVM.loadAll()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(testVM.didCall)
            XCTAssertTrue(phases.contains(.loading))
            XCTAssertTrue(phases.contains(.success))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func test_reloadAll_resetsFiltersAndCallsRefresh() async {
        // prepare
        let testVM = TestableRecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter())
        testVM.searchQuery = "x"
        testVM.selectedCuisine = "y"
        testVM.shouldThrow = false

        await testVM.reloadAll()

        XCTAssertTrue(testVM.didCall)
        XCTAssertEqual(testVM.searchQuery, "")
        XCTAssertNil(testVM.selectedCuisine)
        XCTAssertEqual(testVM.loadPhase, .success)
    }
}

// MARK: - Test doubles

@MainActor
private class FakeRecipeDataService: RecipeDataServiceProtocol {
    @Published var allItems: [Recipe] = []
    @Published var imageCache: any ImageCacheProtocol = FakeImageCache()
    var itemsPublisher: AnyPublisher<[Recipe], Never> { $allItems.eraseToAnyPublisher() }
    func setRecipes(recipes: [Recipe]) {
        print("we loaded recipe with id: \(recipes.first!.id)")
        allItems = recipes }

    // metadata stubs
    func title(for id: UUID) -> String { allItems.first { $0.id == id }?.name ?? "" }
    func description(for id: UUID) -> String { allItems.first { $0.id == id }?.cuisine ?? "" }
    func isNotValid(for id: UUID) -> Bool { false }

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

@MainActor
private class TestableRecipesViewModel: RecipesViewModel {
    var didCall = false
    var shouldThrow = false

    override func loadRecipes(from url: URL? = nil) async throws {
        didCall = true
        if shouldThrow {
            throw NSError(domain: "", code: -1, userInfo: nil)
        }
    }
}
