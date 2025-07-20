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
    
    
    func test_itemsPublisher_updatesItems_setsSelected() {
        let r1 = Recipe(id: UUID(), name: "One", cuisine: "A")
        let r2 = Recipe(id: UUID(), name: "Two", cuisine: "B")
        let expect = expectation(description: "Items updated")
        
        Publishers.CombineLatest(vm.$items, vm.$loadPhase)
            .receive(on: RunLoop.main)
            .first { items, phase in
                items.map(\.id) == [r1.id, r2.id] &&
                phase == .success(.itemsLoaded([r1, r2]))
            }
            .sink { items, _ in
                XCTAssertTrue(items.allSatisfy { $0.selected })
                expect.fulfill()
            }
            .store(in: &cancellables)
        
        service.setRecipes(recipes: [r1, r2])
        wait(for: [expect], timeout: 1)
    }
    
    func test_filterBySearchQuery() {
        let soup = Recipe(id: UUID(), name: "Tomato Soup", cuisine: "Global")
        let salad = Recipe(id: UUID(), name: "Green Salad", cuisine: "Global")
        service.setRecipes(recipes: [soup, salad])
        
        let expectation = XCTestExpectation(description: "Wait for filtered results")
        
        vm.$loadPhase
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink { phase in
                if case .success(.itemsFiltered(let ids)) = phase {
                    if ids == [soup.id] {
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
        
        let expectation = XCTestExpectation(description: "Wait for cuisine categories update")
        
        vm.$loadPhase
            .receive(on: RunLoop.main)
            .sink { phase in
                if case .success(.itemsLoaded) = phase {
                    let categories = Set(self.vm.cusineCategories)
                    if categories == Set(["One", "Two"]) {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        service.setRecipes(recipes: [r1, r2, r3])
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_loadAll_transitionsToSuccess() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json
        
        let testVM = RecipesViewModel(
            recipeStore: service,
            filterStrategy: AllRecipesFilter(),
            networkService: fakeNetwork
        )
        
        let expectation1 = XCTestExpectation(description: "loading")
        let expectation2 = XCTestExpectation(description: "loaded")
        
        testVM.$loadPhase
            .receive(on: RunLoop.main)
            .sink { phase in
                if case .loading = phase {
                    expectation1.fulfill()
                } else if case .success(.itemsLoaded) = phase {
                    expectation2.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await testVM.loadAll()
        await fulfillment(of: [expectation1, expectation2], timeout: 1.0)
    }
    
    func test_reloadAll_resetsFiltersAndCallsRefresh() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json
        
        let testVM = RecipesViewModel(
            recipeStore: service,
            filterStrategy: AllRecipesFilter(),
            networkService: fakeNetwork
        )
        testVM.searchQuery = "x"
        testVM.selectedCuisine = "y"
        
        await testVM.reloadAll()
        
        XCTAssertEqual(testVM.searchQuery, "")
        XCTAssertNil(testVM.selectedCuisine)
    }
    
    func test_loadRecipes_realIntegration_returnData_good() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json
        
        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)
        
        await vm.loadRecipes()
        
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
        
        await vm.loadRecipes()
        
        XCTAssertEqual(service.allItems.count, 1)
        XCTAssertEqual(service.allItems.first?.id, expectedUUID)
        XCTAssertEqual(service.allItems.first?._id, expectedUUID)
    }
    
    func test_loadRecipes_realIntegration_returnData_malformed() async throws {
        let json = try RecipeTestJSON.loadRecipes(.malformed)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json
        
        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)
        
        await vm.loadRecipes()
        
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
        
        await vm.loadRecipes()
        
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
        
        await vm.loadRecipes()
        
        XCTAssertEqual(service.allItems.count, 0)
    }
    
    func test_loadAll_setsFailureOnBadData() async {
        let badData = Data("I am bad data".utf8)
        let fakeNetwork = FakeNetworkService()
        let expectedError = NetworkError.statusCodeFailure(500)
        fakeNetwork.fakeData = badData
        fakeNetwork.error = expectedError
        fakeNetwork.shouldThrow = true
        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)
        
        await vm.loadAll()
        
        guard case .failure(let message) = vm.loadPhase else {
            XCTFail("Expected failure phase")
            return
        }
        XCTAssertEqual(message, expectedError.localizedDescription)
    }
    
    func test_openFilterOptions_defaultValues() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json
        
        let testVM = RecipesViewModel(
            recipeStore: service,
            filterStrategy: AllRecipesFilter(),
            networkService: fakeNetwork
        )
        
        // default query/cuisine vals
        
        testVM.openFilterOptions()
        
        XCTAssertEqual(testVM.searchModel?.text, "")
        XCTAssertTrue(testVM.searchModel!.categories.isEmpty)
    }
    
    func test_openFilterOptions_currentValues() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json
        let vm = RecipesViewModel(recipeStore: service, filterStrategy: AllRecipesFilter(), networkService: fakeNetwork)
        
        let expectation = XCTestExpectation(description: "Items updated")
        
        vm.$items
            .receive(on: RunLoop.main)
            .dropFirst()
            .first(where: { $0.count == 3 })
            .sink { _ in
                vm.openFilterOptions()
                
                XCTAssertEqual(vm.searchModel?.text, "")
                let categories = vm.searchModel!.categories
                
                XCTAssertEqual(categories.count, 2)
                XCTAssertTrue(categories.contains("British"))
                XCTAssertTrue(categories.contains("Malaysian"))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await vm.loadRecipes()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func test_applyFilters_setSelectedCuisine() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        
        let testVM = RecipesViewModel(
            recipeStore: service,
            filterStrategy: AllRecipesFilter(),
            networkService: fakeNetwork
        )
        
        // prepopulated query/cuisine vals
        let recipes = try JSONDecoder().decode(RecipeList.self, from: json).recipes
        let recipeItems = recipes.map { RecipeItem($0) }
        service.setRecipes(recipes: recipes)
        testVM.items = recipeItems
        
        XCTAssertNil(testVM.selectedCuisine)
        
        testVM.applyFilters(cuisine: "British")
        
        XCTAssertEqual(testVM.selectedCuisine, "British")
    }
    
    
    func test_applyFilters_selectItemsByCuisine() {
        let italian = Recipe(id: UUID(), name: "Pizza", cuisine: "Italian")
        let tacos = Recipe(id: UUID(), name: "Taco", cuisine: "Mexican")
        
        let expectation = XCTestExpectation(description: "Wait for filter to apply")
        
        vm.$loadPhase
            .receive(on: RunLoop.main)
            .sink { phase in
                if case .success(.itemsFiltered(let ids)) = phase {
                    XCTAssertEqual(ids, [italian.id])
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        service.setRecipes(recipes: [italian, tacos])
        vm.applyFilters(cuisine: "Italian")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_applyFilters_flow() async throws {
        let json = try RecipeTestJSON.loadRecipes(.good)
        let fakeNetwork = FakeNetworkService()
        fakeNetwork.fakeData = json
        let vm = RecipesViewModel(
            recipeStore: service,
            filterStrategy: AllRecipesFilter(),
            networkService: fakeNetwork)
        
        let expectation = XCTestExpectation(description: "Items updated")
        
        vm.$loadPhase
            .receive(on: RunLoop.main)
            .sink { phase in
                switch phase {
                case .success(.itemsLoaded(let items)) where !items.isEmpty:
                    vm.applyFilters(cuisine: "British")
                case .success(.itemsFiltered(let ids)):
                    XCTAssertTrue(ids.contains(UUID(uuidString: "599344f4-3c5c-4cca-b914-2210e3b3312f")!))
                    XCTAssertTrue(ids.contains(UUID(uuidString: "74f6d4eb-da50-4901-94d1-deae2d8af1d1")!))
                    expectation.fulfill()
                default:
                    return
                }
            }
            .store(in: &cancellables)
        
        await vm.loadRecipes()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}

@MainActor
private class TestableRecipesViewModel: RecipesViewModel {
    var didCall = false
    var shouldThrow = false

    override func loadRecipes(from url: URL? = nil) async {
        didCall = true
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
