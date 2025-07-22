//
//  RecipeMemoryDataSourceProtocol.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/23/25.
//

import Foundation

@MainActor
protocol RecipeMemoryDataSourceProtocol {
    var memories: [UUID: RecipeMemory] { get }
    func load()
    func save()
    func getMemory(for recipeUUID: UUID) -> RecipeMemory
    func isFavorite(for recipeUUID: UUID) -> Bool
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID)
    func toggleFavorite(recipeUUID: UUID)
    func notes(for recipeUUID: UUID) -> [RecipeNote]
    func addNote(_ text: String, for recipeUUID: UUID)
    func deleteNote(for recipeUUID: UUID, noteId: UUID)
    func deleteNotes(for recipeUUID: UUID)
}
