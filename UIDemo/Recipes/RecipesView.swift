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
    @EnvironmentObject private var nav: AppNavigation

    @State private var bold = false
    @State private var italic = false
    
    @State private var fontSize = 12.0
    @State private var searchPresented = false
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        List(vm.items, id: \.id) { item in
            RecipeRowView(item: item) {
                vm.toggleFavorite(recipeUUID: item.id)
            }
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.automatic)
        .listRowSpacing(10)
        .navigationTitle("Recipes")
        .refreshable {
            await FetchCache.shared.refresh()
        }
        .task {
            print("list element appeared")
            
            do {
                // Pick the correct folder name: "DevelopmentFetchImageCache" "FetchImageCache"
            #if DEBUG
                try vm.startCache(path: "DevelopmentFetchImageCache")
            #else
                try vm.startCache(path: "FetchImageCache")
            #endif
            } catch {
                print("it was the cache")
                return
                // failed to start cache. what do i do here? is vm.items = [] appropriate?
            }
            await vm.loadRecipes()
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                IconButton(icon: .system("magnifyingglass"), isDisabled: .constant(false)) {
                    vm.selectedCuisine = "british"
                }
                .asStandardIconButtonStyle()
            }
        }
        .popover(item: $vm.searchModel) { model in
            Button(action: {
                vm.selectedCuisine = "british"
                
            }, label: {Text("filter")})
        }
    }
}


#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    @State var strring = "https%3A//d3jbb8n5wk0qxi.cloudfront.net/photos/.../small.jpg"
    
    static var previews: some View {
        @StateObject var vm = RecipesViewModel(cache: FetchCache.shared, memoryStore: RecipeDataSource.shared)
        @StateObject var nav = AppNavigation.shared
        
//        @StateObject var memoryStore = RecipeDataSource.shared
        
        @StateObject var themeManager: ThemeManager = ThemeManager()
        // TODO: Test resizing here later.
        
        NavigationStack {
            RecipesView(vm: vm)
                .environmentObject(themeManager)
                .environmentObject(nav)
        }
    }
}
#endif
