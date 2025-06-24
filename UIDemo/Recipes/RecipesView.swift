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
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        List {
            Section(header: searchHeaderView) {
                ForEach(vm.items, id: \.id) { item in
                    RecipeRowView(item: item) {
                        withAnimation {
                            vm.toggleFavorite(recipeUUID: item.id)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Recipes")
        .refreshable {
            await FetchCache.shared.refresh()
        }
        .task {
            do {
#if DEBUG
                try vm.startCache(path: "DevelopmentFetchImageCache")
#else
                try vm.startCache(path: "FetchImageCache")
#endif
            } catch {
                print("Cache failed to start")
                return
            }
            await vm.loadRecipes()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                IconButton(
                    icon: .system("line.3.horizontal.decrease.circle\(vm.selectedCuisine != nil ? ".fill" : "")"),
                    isDisabled: .constant(false)
                ) {
                    withAnimation(.spring()) {
                        vm.searchModel = SearchViewModel(
                            text: vm.searchQuery,
                            categories: vm.cusineCategories
                        )
                    }
                }
                .asStandardIconButtonStyle(withColor: vm.selectedCuisine != nil ? .blue : .gray)
                .rotationEffect(.degrees(vm.selectedCuisine != nil ? 90 : 0))
                .scaleEffect(vm.selectedCuisine != nil ? 1.2 : 1.0)
            }
        }
        .sheet(item: $vm.searchModel) { model in
            RecipeSearchFilterSheet(
                model: model,
                selectedCuisine: vm.selectedCuisine,
                onSelect: { cuisine in
                    withAnimation {
                        vm.selectedCuisine = cuisine
                    }
                    vm.searchModel = nil
                },
                onReset: {
                    withAnimation {
                        vm.selectedCuisine = nil
                    }
                    vm.searchModel = nil
                }
            )
        }
    }
    
    private var searchHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search recipes", text: $vm.searchQuery)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if !vm.searchQuery.isEmpty {
                Button(action: { vm.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
