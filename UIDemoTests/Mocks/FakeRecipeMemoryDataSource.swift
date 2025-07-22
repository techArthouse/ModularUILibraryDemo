////
////  RecipeMemoryDataSourceTests.swift
////  UIDemoTests
////
////  Created by Arturo Aguilar on 7/14/25.
////
import XCTest
import SwiftUI
@testable import UIDemo

// MARK: - the fake function simpulate what we sho0uld epect.
@MainActor
private class FakeMemoryDataSource: RecipeMemoryDataSourceProtocol {
    func deleteNote(for recipeUUID: UUID, noteId: UUID) {
    }
    
    var memories: [UUID: RecipeMemory] = [:]
    func load() {}
    func save() {}
    func getMemory(for recipeUUID: UUID) -> RecipeMemory {
        memories[recipeUUID] ?? RecipeMemory(isFavorite: false, notes: [])
    }
    func isFavorite(for recipeUUID: UUID) -> Bool {
        getMemory(for: recipeUUID).isFavorite
    }
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) {
        var m = getMemory(for: recipeUUID)
        m.isFavorite = favorite
        memories[recipeUUID] = m
    }
    func toggleFavorite(recipeUUID: UUID) {
        var m = getMemory(for: recipeUUID)
        m.isFavorite.toggle()
        memories[recipeUUID] = m
    }
    func notes(for recipeUUID: UUID) -> [RecipeNote] {
        getMemory(for: recipeUUID).notes
    }
    func addNote(_ text: String, for recipeUUID: UUID) {
        var m = getMemory(for: recipeUUID)
        m.notes.append(RecipeNote(id: UUID(), text: text, date: Date()))
        memories[recipeUUID] = m
    }
    func deleteNotes(for recipeUUID: UUID) {
        var m = getMemory(for: recipeUUID)
        m.notes.removeAll()
        memories[recipeUUID] = m
    }
}

