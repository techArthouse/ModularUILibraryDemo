//
//  RecipeItem.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

/// RecipeItem is a lightweight projection model used by vms to show/hide recipe. it abstracts the recipes identity
/// from data flow interactions with recipe views and handlers
@MainActor
class RecipeItem: ObservableObject, Identifiable, Equatable {
    let id: UUID // essential and nonmutating
    @Published var shouldShow: Bool
    
    init(_ recipe: Recipe) {
        self.id = recipe.id
        self.shouldShow = false
    }
    
    nonisolated static func == (lhs: RecipeItem, rhs: RecipeItem) -> Bool {
        lhs.id == rhs.id
    }
}
