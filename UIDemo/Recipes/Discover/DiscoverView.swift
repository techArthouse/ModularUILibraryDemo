//
//  DiscoverView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/19/25.
//

import SwiftUI
import ModularUILibrary

struct DiscoverView: View {
    @ObservedObject var vm: DiscoverViewModel
    @EnvironmentObject private var nav: AppNavigation
    @State private var selectedID: UUID?
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text("Discover something ")
                    .font(.robotoMono.regular(size: 20))
                    .padding(0)
                Text("new")
                    .font(.robotoMono.regular(size: 20).bold().italic())
                    .foregroundStyle(.orange)
                    .padding(0)
                Text("!")
                    .font(.robotoMono.regular(size: 20).italic())
            }
            
            RandomRecipeButton(recipeStore: vm.recipeStore, selectedID: $selectedID)
                .onChange(of: selectedID) { newId in
                    guard let newId = newId else { return }
                    Logger.log("Selected recipe (onChange legacy): \(newId)")
                    nav.discoverPath.append(.recipeDetail(newId))
                }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

// MARK: - DEBUG Structures/Previews

#if DEBUG
struct DiscoverView_Previews: PreviewProvider {
    
    static var previews: some View {
        let recipeStore = RecipeDataService(memoryStore: RecipeMemoryDataSource(), fetchCache: MockFetchCache())
        let vm = DiscoverViewModel(recipeStore: recipeStore)
        
        let r1 = Recipe(id: UUID(), name: "A", cuisine: "One")
        let r2 = Recipe(id: UUID(), name: "B", cuisine: "Two")
        let r3 = Recipe(id: UUID(), name: "C", cuisine: "Two")
        recipeStore.setRecipes(recipes: [r1, r2, r3])
        
        let nav = AppNavigation.shared
        let themeManager: ThemeManager = ThemeManager()
        
        return NavigationStack {
            DiscoverView(vm: vm)
                .environmentObject(themeManager)
                .environmentObject(nav)
        }
    }
}
#endif
