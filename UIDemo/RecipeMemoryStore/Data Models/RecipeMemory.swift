//
//  RecipeMemory.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/13/25.
//

import Foundation

class RecipeMemory: Codable, ObservableObject {
    var isFavorite: Bool
    var notes: [RecipeNote]
    
    init(isFavorite: Bool, notes: [RecipeNote]) {
        self.isFavorite = isFavorite
        self.notes = notes
    }
}
