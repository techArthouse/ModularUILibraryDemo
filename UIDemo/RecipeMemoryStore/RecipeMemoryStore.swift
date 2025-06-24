//
//  RecipeMemoryStore.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/23/25.
//

import Foundation

@MainActor
protocol RecipeMemoryStoreProtocol {
    func isFavorite(for recipeUUID: UUID) -> Bool
    func notes(for recipeUUID: UUID) -> [RecipeNote]
    func addNote(_ text: String, for recipeUUID: UUID)
    func toggleFavorite(recipeUUID: UUID)
}
