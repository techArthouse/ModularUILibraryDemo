//
//  RecipeRowViewModelTests.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/17/25.
//


import XCTest
import SwiftUI
import Combine
@testable import UIDemo

@MainActor
final class RecipeRowViewModelTests: XCTestCase {
    private var store: FakeRecipeDataService!
    private var vm: RecipeRowViewModel!
    private var recipe: Recipe!
    private var invalideRecipe: Recipe!
    
    override func setUp() {
        super.setUp()
        store = FakeRecipeDataService()
        recipe = Recipe(id: UUID(), name: "Test Soup", cuisine: "Global")
        store.setRecipes(recipes: [recipe])
        vm = RecipeRowViewModel(recipeId: recipe.id, recipeStore: store)
    }

    override func tearDown() {
        vm = nil
        store = nil
        recipe = nil
        super.tearDown()
    }

    func test_titleAndDescription_matchRecipe() {
        XCTAssertEqual(vm.title, recipe.name)
        XCTAssertEqual(vm.description, recipe.cuisine)
    }

    func test_isFavorite_binding_readsAndWritesCorrectly() {
        XCTAssertFalse(vm.isFavorite)  // Should default to false
        XCTAssertFalse(vm.isFavoriteBinding.wrappedValue)

        // Now set to favorite through the binding
        vm.isFavoriteBinding.wrappedValue = true

        XCTAssertTrue(store.isFavorite(for: recipe.id))
        XCTAssertTrue(vm.isFavoriteBinding.wrappedValue)
    }

    func test_toggleFavorite_flipsStateCorrectly() {
        let original = store.isFavorite(for: recipe.id)
        vm.toggleFavorite()
        XCTAssertNotEqual(store.isFavorite(for: recipe.id), original)
    }

    func test_addNote_notFavorite() { // add note should fail if not favorited recipe
        let noteText = "Delicious test note"
        vm.addNote(noteText)

        let notes = store.notes(for: recipe.id)
        XCTAssertEqual(notes.count, 0)
    }
    
    func test_addNote_isFavorite() {
        let noteText = "Delicious test note"
        vm.setFavorite(true)
        vm.addNote(noteText)

        let notes = store.notes(for: recipe.id)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.text, noteText)
    }
    
    func test_imageLoad_setsImage() async {
        await vm.load()

        XCTAssertNotNil(vm.image)
    }

    func test_isNotValid_true() {
        invalideRecipe = Recipe(id: UUID(), name: nil, cuisine: "Latin")
        store.setRecipes(recipes: [invalideRecipe])
        vm = RecipeRowViewModel(recipeId: invalideRecipe.id, recipeStore: store)
        
        XCTAssertTrue(vm.isNotValid)
    }

    func test_isNotValid_false() {
        XCTAssertFalse(vm.isNotValid)
    }
}
