//
//  RandomRecipeButton.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/19/25.
//

import SwiftUI

struct RandomRecipeButton: View {
    let recipeStore: any RecipeDataServiceProtocol
    @Binding var selectedID: UUID?

    var body: some View {
        VStack {
            Button("View Random Recipe") {
                selectRandomUnfavoritedRecipe()
            }
        }
    }

    private func selectRandomUnfavoritedRecipe() {
        guard let id = recipeStore.allItems.filter({ !recipeStore.isFavorite(for: $0.id) }).randomElement()?.id else {
            return
        }
        selectedID = id
    }
}
