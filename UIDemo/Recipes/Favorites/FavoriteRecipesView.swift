//
//  FavoriteRecipesView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/27/25.
//

import SwiftUI
import ModularUILibrary

// MARK: - Recipes List View
struct FavoriteRecipesView: View {
    @ObservedObject private var vm: RecipesViewModel
    @EnvironmentObject private var nav: AppNavigation
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        List{
            Section(header: searchHeaderView) {
                ForEach(vm.items, id: \.id) { item in
                    if item.isFavorite {
                        FavoriteRecipeCard(viewmodel: RecipeRowViewModel(recipeId: item.id, recipeStore: vm.recipeStore)) {
                            nav.path2.append(.recipeDetail(item.id))
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
                .listRowBackground(Color.clear)
            }
        }
        .animation(.easeInOut, value: vm.items.map(\.isFavorite))
        .listStyle(.plain)
        .task { vm.loadAll() }
        .refreshable { await vm.reloadAll() }
        .navigationTitle("Favorite Recipes")
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
                    vm.searchModel = nil
                    vm.selectedCuisine = cuisine
                },
                onReset: {
                    vm.searchModel = nil
                    vm.selectedCuisine = nil
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
