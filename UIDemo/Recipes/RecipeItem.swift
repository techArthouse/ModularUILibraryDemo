//
//  RecipeItem.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

/// RecipeItem is a lightweight projection model that holds the state of ui observed varaibles and shared across views.
@MainActor
class RecipeItem: ObservableObject, Identifiable {
    let id: UUID // essential and nonmutating
    @Published var isFavorite: Bool = false // is favorite is potentially toggled often enough that we need to watch it.
    @Published var notes: [RecipeNote] = []
    @Published var selected: Bool // we've discussed this one.

    init(id: UUID, selected: Bool = true) {
        self.id = id
        self.selected = selected
    }
    
    init(_ recipe: Recipe) {
        self.id = recipe.id
        self.selected = true
    }
}
