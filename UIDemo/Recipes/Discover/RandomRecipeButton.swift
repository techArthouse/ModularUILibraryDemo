//
//  RandomRecipeButton.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/19/25.
//

import SwiftUI
import ModularUILibrary

/// Button composite view that takes a use to a random, unfavorited recipe. 
struct RandomRecipeButton: View {
    let recipeStore: any RecipeDataServiceProtocol
    @Binding var selectedID: UUID?

    var body: some View {
        VStack {
            CTAButton(title: "View Random Recipe", icon: .system("fork.knife")) {
                selectRandomUnfavoritedRecipe()
            }
            .asPrimaryAlertButton(padding: .manualPadding)
            .padding(.horizontal, 30)
            .padding(.top, 10)
        }
    }

    private func selectRandomUnfavoritedRecipe() {
        guard let id = recipeStore.allItems.filter({ !recipeStore.isFavorite(for: $0.id) }).randomElement()?.id else {
            return
        }
        selectedID = id
    }
}

#if DEBUG
struct RandomRecipeButton_Previews: PreviewProvider {
    static var previews: some View {
        let memoryStore = RecipeMemoryDataSource()
        let networkService = NetworkService()
        let recipeStore = RecipeDataService(
            memoryStore: memoryStore,
            fetchCache: CustomAsyncImageCache(path: "PreviewCache", networkService: networkService)
        )
        let themeManager: ThemeManager = ThemeManager()

        RandomRecipeButton(recipeStore: recipeStore, selectedID: .constant(UUID()))
        .environmentObject(themeManager)
    }
}
#endif
