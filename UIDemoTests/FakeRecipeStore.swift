//
//  RecipesViewModelTests.swift
//  UIDemoTests
//
//  Created by Arturo Aguilar on 7/12/25.
//
import XCTest
import Combine
@testable import UIDemo

/// A fake RecipeStore that lets us publish custom recipe arrays and observe how the view model reacts.
private class FakeRecipeStore: RecipeStore {
    let subject = CurrentValueSubject<[Recipe], Never>([])
    override var itemsPublisher: AnyPublisher<[Recipe], Never> { subject.eraseToAnyPublisher() }
    override var allItems: [Recipe] { subject.value }
    override func refresh() async { }
    func sendRecipes(_ recipes: [Recipe]) { subject.send(recipes) }
}pppt: String, for recipeUUID: UUID) -> RecipeNote? { nil }
    func deleteNotes(for recipeUUID: UUID) { }
    func toggleFavorite(recipeUUID: UUID) {
        if favorites.contains(recipeUUID) { favorites.remove(recipeUUID) } else { favorites.insert(recipeUUID) }
    }
}

/// A subclass of RecipesViewModel that overrides loadRecipes to simulate success or failure.
@MainActor
private class TestableRecipesViewModel: RecipesViewModel {
    var didCallLoadRecipes = false
    var shouldThrowError = false

    override func loadRecipes(from url: URL? = nil) async throws {
        didCallLoadRecipes = true
        if shouldThrowError {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        // simulate loading - no action
    }
}

@MainActor
final class RecipesViewModelTests: XCTestCase {
    private var store: FakeRecipeStore!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        store = FakeRecipeStore(memoryStore: RecipeMemoryDataSource.shared,
                                fetchCache: FetchCache(path: "TestCache"))
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        store = nil
        super.tearDown()
    }

    func testItemsPublisherUpdatesItems() throws {
        let vm = RecipesViewModel(recipeStore: store, filterStrategy: AllRecipesFilter())
        let exp = expectation(description: "Items update")
        let sample = Recipe(id: UUID(), name: "Test", cuisine: "Global")

        vm.$items
            .dropFirst()
            .sink { items in
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items.first?.id, sample.id)
                XCTAssertTrue(items.first?.selected ?? false)
                exp.fulfill()
            }
            .store(in: &cancellables)

        store.sendRecipes([sample])
        waitForExpectations(timeout: 1)
    }

    func testFilteringByCuisineAndQuery() {
        let vm = RecipesViewModel(recipeStore: store, filterStrategy: AllRecipesFilter())
        let italian = Recipe(id: UUID(), name: "Pizza", cuisine: "Italian")
        let tacos = Recipe(id: UUID(), name: "Taco", cuisine: "Mexican")

        store.sendRecipes([italian, tacos])
        XCTAssertTrue(vm.items.map({ $0.selected }).allSatisfy { $0 })

        vm.selectedCuisine = "Italian"
        XCTAssertEqual(vm.items.filter({$0.selected}).map({$0.id}), [italian.id])

        vm.selectedCuisine = nil
        vm.searchQuery = "Taco"
        XCTAssertEqual(vm.items.filter({$0.selected}).map({$0.id}), [tacos.id])
    }

    func testCuisineCategoriesWithSelection() {
        let vm = RecipesViewModel(recipeStore: store, filterStrategy: AllRecipesFilter())
        let r1 = Recipe(id: UUID(), name: "A", cuisine: "One")
        let r2 = Recipe(id: UUID(), name: "B", cuisine: "Two")
        store.sendRecipes([r1, r2])
        let cats = vm.cusineCategories
        XCTAssertEqual(Set(cats), ["One", "Two"] )
    }

    func testLoadAllPhaseTransitionsToSuccess() {
        let vm = TestableRecipesViewModel(recipeStore: store, filterStrategy: AllRecipesFilter())
        let exp = expectation(description: "phase")
        var phases = [RecipesViewModel.LoadPhase]()
        vm.$loadPhase.sink { phases.append($0) }.store(in: &cancellables)
        vm.shouldThrowError = false
        vm.loadAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(vm.didCallLoadRecipes)
            XCTAssertTrue(phases.contains(.loading))
            XCTAssertTrue(phases.contains(.success))
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testLoadAllPhaseTransitionsToFailure() {
        let vm = TestableRecipesViewModel(recipeStore: store, filterStrategy: AllRecipesFilter())
        let exp = expectation(description: "failure phase")
        var phases = [RecipesViewModel.LoadPhase]()
        vm.$loadPhase.sink { phases.append($0) }.store(in: &cancellables)
        vm.shouldThrowError = true
        vm.loadAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(vm.didCallLoadRecipes)
            XCTAssertTrue(phases.contains { if case .failure = $0 { return true } else { return false } })
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testReloadAllResetsStateAndSucceeds() async {
        let vm = TestableRecipesViewModel(recipeStore: store, filterStrategy: AllRecipesFilter())
        vm.searchQuery = "x"
        vm.selectedCuisine = "y"
        vm.searchModel = SearchViewModel(text: "t", categories: [])
        vm.shouldThrowError = false
        await vm.reloadAll()
        XCTAssertTrue(vm.didCallLoadRecipes)
        XCTAssertEqual(vm.searchQuery, "")
        XCTAssertNil(vm.selectedCuisine)
        XCTAssertNil(vm.searchModel)
        XCTAssertEqual(vm.loadPhase, .success)
    }

    func testFavoriteFilterOnlyShowsFavorites() {
        let memory = FakeMemoryStore()
        let favStore = FakeRecipeStore(memoryStore: memory, fetchCache: FetchCache(path: "TestCache"))
        let vm = RecipesViewModel(recipeStore: favStore, filterStrategy: FavoriteRecipesFilter())
        let r1 = Recipe(id: UUID(), name: "1", cuisine: "C")
        let r2 = Recipe(id: UUID(), name: "2", cuisine: "C")
        memory.favorites.insert(r2.id)
        favStore.sendRecipes([r1, r2])
        XCTAssertEqual(vm.items.filter({$0.selected}).map({$0.id}), [r2.id])
    }
}
