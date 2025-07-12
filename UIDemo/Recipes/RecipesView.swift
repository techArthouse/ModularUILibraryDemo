//
//  RecipesView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import ModularUILibrary

/// RecipesView is a root view and displays all recipes from the network.
struct RecipesView: View {
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
                VStack(spacing: 16) {
                    Text("Error: \(msg)")
                        .multilineTextAlignment(.center)
                    Button("Retry", action: vm.loadAll)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .success:
                contentList
            }
        }
        .task { vm.loadAll() }
        .refreshable { _ = await vm.reloadAll() }
        .navigationTitle("Recipes")
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
    
    // main body composition
    private var contentList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                searchHeaderView
                Divider()
                    .frame(height: 1)
                    .background(.black.opacity(0.5))
                ForEach(vm.items, id: \.id) { item in
                    if item.selected {
                        RecipeRowView(viewmodel: RecipeRowViewModel(recipeId: item.id, recipeStore: vm.recipeStore)) {
                            nav.path.append(.recipeDetail(item.id))
                        }
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .trailing))
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 3)
            }
            .padding(.horizontal, 5)
            .background{
                RoundedRectangle(cornerRadius: 0)
                    .fill(.gray.opacity(0.09))
                    .shadow(color: .black, radius: 1)
                
            }
            .cornerRadius(4)
            .animation(.easeInOut, value: vm.items.map(\.selected))
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
        .cornerRadius(10)
        .background(Color(.white))
        .border(.black, width: 0.5)
    }
}


#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    @State var strring = "https%3A//d3jbb8n5wk0qxi.cloudfront.net/photos/.../small.jpg"
    
    static var previews: some View {
        @StateObject var recipeStore = RecipeStore(memoryStore: RecipeMemoryDataSource.shared, fetchCache: MockFetchCache())
        @StateObject var vm = RecipesViewModel(recipeStore: recipeStore, filterStrategy: AllRecipesFilter())
        @StateObject var nav = AppNavigation.shared
        @StateObject var themeManager: ThemeManager = ThemeManager()
        
        NavigationStack {
            RecipesView(vm: vm)
                .environmentObject(themeManager)
                .environmentObject(nav)
                .environmentObject(FetchCache())
        }
    }
}
#endif
