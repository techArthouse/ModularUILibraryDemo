//
//  RecipesView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import ModularUILibrary

/// Displays a list of recipes based on the provided view model.
/// Handles loading states, errors, refresh, and navigation to details.
struct RecipesView: View {
    /// The view model that drives the view's content and state.
    @ObservedObject private var vm: RecipesViewModel
    /// Shared navigation object for pushing detail views.
    @EnvironmentObject private var nav: AppNavigation
    
    /// Creates a RecipesView with a default thumbnail size and its view model.
    /// - Parameters:
    ///   - defaultSize: The image size to render for each recipe row.
    ///   - vm: The view model containing recipes and state.
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
                case .itemsEmpty:
                    errorView(type: .noResults)
                default:
                    contentList
                }
            }
        }
        .task {
            await vm.loadAll()
        }
        .refreshable { _ = await vm.reloadAll() }
        .navigationTitle("Recipes")
        .toolbar { toolbarItems }
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
    
    /// Builds the main scrollable list of recipes.
    private var contentList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    searchHeaderView
                    Divider().frame(height: 1)
                        .background(.black.opacity(0.5))
                    ForEach(vm.items, id: \.id) { item in
                        if item.shouldShow {
                            RecipeRowView(makeRecipeRowVM: { RecipeRowViewModel(recipeId: item.id, recipeStore: vm.recipeStore, imageSize: .small)} ) {
                                nav.homePath.append(.recipeDetail(item.id))
                            }
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .move(edge: .trailing)
                            ))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 3)
                }
                .padding(.horizontal, 5)
                .cornerRadius(4)
                .animation(.easeInOut, value: vm.items.map(\.shouldShow))
            }
        }
    }
    
    /// The search bar header placed at the top of the recipe list.
    private var searchHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search recipes", text: $vm.searchQuery)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if !vm.searchQuery.isEmpty {
                Button(action: { vm.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .cornerRadius(10)
        .background(Color(.white))
        .border(.black, width: 0.5)
    }
    
    /// Toolbar items including filters and actions.
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            IconButton(
                icon: .system("line.3.horizontal.decrease.circle\(vm.selectedCuisine != nil ? ".fill" : "")"),
                isDisabled: .constant(false)
            ) {
                withAnimation(.spring()) {
                    vm.openFilterOptions()
                }
            }
            .asStandardIconButtonStyle(
                withColor: vm.selectedCuisine != nil ? .blue : .gray
            )
            .rotationEffect(.degrees(vm.selectedCuisine != nil ? 90 : 0))
            .scaleEffect(vm.selectedCuisine != nil ? 1.2 : 1.0)
        }
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
                    Text("No recipes found.")
                        .font(.robotoMono.regular(size: 20).bold())
                        .multilineTextAlignment(.center)
                        
                    CTAButton(title: "Retry") {
                        Task {
                            await vm.reloadAll()
                        }
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

// MARK: - DEBUG Structures/Previews

#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        let recipeStore = RecipeDataService(memoryStore: RecipeMemoryDataSource(), fetchCache: MockFetchCache())
        @StateObject var vm = RecipesViewModel(recipeStore: recipeStore, filterStrategy: AllRecipesFilter(), networkService: NetworkService())
        @StateObject var nav = AppNavigation.shared
        @StateObject var themeManager: ThemeManager = ThemeManager()
        
        NavigationStack {
            RecipesView(vm: vm)
                .environmentObject(themeManager)
                .environmentObject(nav)
        }
    }
}
#endif
