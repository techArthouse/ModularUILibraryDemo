//
//  DiscoverViewModel.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/19/25.
//

import SwiftUI

@MainActor
final class DiscoverViewModel: ObservableObject {
    let recipeStore: any RecipeDataServiceProtocol
    
    init(recipeStore: any RecipeDataServiceProtocol) {
        self.recipeStore = recipeStore
    }
}
