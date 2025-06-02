//
//  RecipesView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import Combine
import ModularUILibrary

// MARK: - Recipes List View
struct RecipesView: View {
    @ObservedObject private var vm: RecipesViewModel
//    @State var imageSize: Constants.ImageSize
    //    @EnvironmentObject private var themeManager: ThemeManager
    
    init(defaultSize: Constants.ImageSize = .medium,
         vm: RecipesViewModel
    ) {
//        _ = FetchCache.shared
//        self.imageSize = defaultSize
        _ = FetchCache.shared
        self.vm = vm
    }
    
    var body: some View {
        List(vm.items, id: \.id) { item in
            RecipeRowView(item: item)
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.automatic)
        .listRowSpacing(10)
        .navigationTitle("Recipes")
        .refreshable {
            FetchCache.shared.refresh()
        }
        .onAppear {
            print("list element appeared")
            vm.loadRecipes()
        }
    }
    
    struct RecipeRowView: View {
        // Suppose the parent passed us a Binding<RecipeItem>:
        @ObservedObject var item: RecipeItem

        var body: some View {
            
            FeatureItem(
                title: item.name,
                description: item.cuisine,
                leading: {
                    ImageContainer(image: item.image, accessibilityId: item.id)
                })
            .task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                item.image = Image(systemName: "heart.fill")
            }
        }
    }
}

#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var vm = RecipesViewModel()
        let themeManager: ThemeManager = ThemeManager()
        // TODO: Test resizing here later.
        
        NavigationStack {
            RecipesView(vm: vm)
                .environmentObject(themeManager)
        }
    }
}
#endif
