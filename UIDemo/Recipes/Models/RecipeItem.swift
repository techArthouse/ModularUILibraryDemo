//
//  RecipeItem.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

/// RecipeItem is a lightweight projection model that holds the state of ui observed varaibles and shared across views.
@MainActor
class RecipeItem: ObservableObject, Identifiable, Equatable {
    let id: UUID // essential and nonmutating
    @Published var selected: Bool
    
    init(_ recipe: Recipe) {
        self.id = recipe.id
        self.selected = false
    }
    
    nonisolated static func == (lhs: RecipeItem, rhs: RecipeItem) -> Bool {
        lhs.id == rhs.id
    }
}
