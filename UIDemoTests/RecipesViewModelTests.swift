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
        let fakeNetwork = FakeNetworkService()
        vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)
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
        let testVM = TestableRecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: FakeNetworkService())
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
        let testVM = TestableRecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: FakeNetworkService())
        testVM.searchQuery = "x"
        testVM.selectedCuisine = "y"
        testVM.shouldThrow = false

        await testVM.reloadAll()

        XCTAssertTrue(testVM.didCall)
        XCTAssertEqual(testVM.searchQuery, "")
        XCTAssertNil(testVM.selectedCuisine)
        XCTAssertEqual(testVM.loadPhase, .success)
    }
    
    func test_loadRecipes_realIntegration_returnData_good() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json

        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)

        try await vm.loadRecipes()

        XCTAssertEqual(service.allItems.count, 3)
        XCTAssertEqual(service.allItems.first?.name, "Apam Balik")
        XCTAssertEqual(service.allItems.last?.cuisine, "British")
    }
    
    func test_loadRecipes_realIntegration_returnData_expectedUUID() async throws {
        let expectedUUID = UUID()
        let fakeJSON = """
            {
                "recipes": [
                    { "uuid": "\(expectedUUID)", "name": "Fake Recipe", "cuisine": "Test" }
                ]
            }
            """.data(using: .utf8)!
        
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = fakeJSON

        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)

        try await vm.loadRecipes()

        XCTAssertEqual(service.allItems.count, 1)
        XCTAssertEqual(service.allItems.first?.id, expectedUUID)
        XCTAssertEqual(service.allItems.first?._id, expectedUUID)
    }
    
    func test_loadRecipes_realIntegration_returnData_malformed() async throws {
        let json = try RecipeTestJSON.loadRecipes(.malformed)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json

        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)

        try await vm.loadRecipes()

        XCTAssertEqual(service.allItems.count, 3)
        
        // recipe missing cuisine
        XCTAssertEqual(service.allItems.first?.name, "Missing Cuisine")
        XCTAssertEqual(service.allItems.first?.cuisine, "N/A")
        XCTAssertNil(service.allItems.first?._cuisine)
        
        // recipe missing name
        XCTAssertEqual(service.allItems[1].cuisine, "Missing Name")
        XCTAssertEqual(service.allItems[1].name, "N/A")
        XCTAssertNil(service.allItems[1]._name)
        
    }
    
    func test_loadRecipes_realIntegration_returnData_malformed_UUID() async throws {
        let json = try RecipeTestJSON.loadRecipes(.malformed)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json

        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)

        try await vm.loadRecipes()

        XCTAssertEqual(service.allItems.count, 3)
        
        // recipe missing uuid
        XCTAssertEqual(service.allItems.last?.name, "Missing UUID")
        XCTAssertNil(service.allItems.last?._id)
        XCTAssertNotNil(service.allItems.last?.id)
    }
    
    func test_loadRecipes_realIntegration_returnData_empty() async throws {
        let json = try RecipeTestJSON.loadRecipes(.empty)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json

        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)

        try await vm.loadRecipes()

        XCTAssertEqual(service.allItems.count, 0)
    }
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

enum RecipeTestJSON {
    enum TestCase: String {
        case good = "recipesGood"
        case malformed = "recipesMalformed"
        case empty = "recipesEmpty"

        var fileName: String { rawValue }
    }

    static func loadRecipes(_ caseType: TestCase) throws -> Data {
        let bundle = Bundle(for: UIDemoTests.self)
        guard let url = bundle.url(forResource: caseType.fileName, withExtension: "json") else {
            throw NSError(domain: "File not found", code: 404)
        }
        return try Data(contentsOf: url)
    }
}
