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
        Group {
            switch vm.loadPhase {
            case .idle, .loading:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure(let msg):
                errorView(type: .error(msg))
            case .success(let phase):
                switch phase {
                case .itemsLoaded(let recipes) where recipes.isEmpty:
                    errorView(type: .noResults)
                default:
                    contentList
                }
            }
        }
        .task {
            Logger.log("tasking again in favorites")
            await vm.loadAll()
        }
        .refreshable { await vm.reloadAll() }
        .navigationTitle("Favorite Recipes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                IconButton(
                    icon: .system("line.3.horizontal.decrease.circle\(vm.selectedCuisine != nil ? ".fill" : "")"),
                    isDisabled: .constant(false)
                ) {
                    withAnimation(.spring()) {
                        vm.openFilterOptions()
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
                    vm.applyFilters(cuisine: cuisine)
                },
                onReset: {
                    vm.searchModel = nil
                    vm.applyFilters(cuisine: nil)
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
        .border(.black, width: 0.5)
    }
    
    private var contentList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 15) {
                searchHeaderView
                ForEach(vm.items, id: \.id) { item in
                    if item.selected {
                        FavoriteRecipeCard(makeRecipeRowVM: { RecipeRowViewModel(recipeId: item.id, recipeStore: vm.recipeStore) }) {
                            nav.favoritesPath.append(.recipeDetail(item.id))
                        }
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .trailing))
                        )
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
                .listRowBackground(Color.clear)
            }
            .padding(.horizontal, 10)
        }
        .animation(.easeInOut, value: vm.items.map(\.selected))
        .listStyle(.plain)
    }
    
    /// Renders an error state with a retry button.
    /// - Parameter type: the type of error state to display
    private func errorView(type: ErrorState) -> some View {
        Group {
            switch type {
            case .error(let message):
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Error")
                            .font(.robotoMono.regular(size: 30).bold())
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        Text("\(message)")
                            .font(.robotoMono.regular(size: 20).bold())
                            .multilineTextAlignment(.center)
                    }
                    
                    CTAButton(title: "Retry") {
                        Task {
                            await vm.reloadAll()
                        }
                    }
                    .asDestructiveButton()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .noResults:
                VStack(spacing: 16) {
                    Text("No Favorites")
                        .font(.robotoMono.regular(size: 25).bold())
                        .multilineTextAlignment(.center)
                    Text("Save Recipes to your favorites by tapping the star icon next to a recipe.")
                        .multilineTextAlignment(.center)
                        
                    CTAButton(title: "View Recipes") {
                        nav.selectedTab = .home
                    }
                    .asPrimaryAlertButton()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private enum ErrorState {
        case error(String)
        case noResults
    }
}
