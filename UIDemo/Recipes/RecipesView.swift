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
                    RecipeRowView(item: item, onToggleFavorite: {
                        withAnimation {
                            vm.toggleFavorite(recipeUUID: item.id)
                        }
                    }) {
                        nav.path.append(.recipeDetail(item.id))
                    }
                    .listRowInsets(EdgeInsets())
                }
            }
        }
        .animation(.easeInOut, value: vm.items)
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
                await vm.loadRecipes()
            } catch {
                print("Cache failed to start")
                return
            }
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


#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    @State var strring = "https%3A//d3jbb8n5wk0qxi.cloudfront.net/photos/.../small.jpg"
    
    static var previews: some View {
        @StateObject var recipeStore = RecipeStore()
        @StateObject var vm = RecipesViewModel(memoryStore: RecipeDataSource.shared, recipeStore: recipeStore, filterStrategy: FavoriteRecipesFilter())
        @StateObject var nav = AppNavigation.shared
        
        @StateObject var themeManager: ThemeManager = ThemeManager()
        // TODO: Test resizing here later.
        
        NavigationStack {
            FavoriteRecipesView(vm: vm)
                .environmentObject(themeManager)
                .environmentObject(nav)
        }
    }
}
#endif


// MARK: - Recipes List View
struct FavoriteRecipesView: View {
    @ObservedObject private var vm: RecipesViewModel
    @EnvironmentObject private var nav: AppNavigation
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        ScrollView {
            Section(header: searchHeaderView) {
                ForEach($vm.items, id: \.id) { $item in
                    FavoriteRecipeCard(item: $item.wrappedValue)
                        .gesture(TapGesture().onEnded({
                            nav.path2.append(.recipeDetail(item.id))
                        }), including: .gesture)
                }
            }
        }
        .animation(.easeInOut, value: vm.items)
        .navigationTitle("Favorites")
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
                await vm.loadRecipes()
            } catch let error as FetchCacheError {
                switch error {
                case .directoryAlreadyOpenWithPathComponent:
                    print("Cache already exists")
                default:
                    break
                }
            } catch {
                
            }
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

struct FavoriteRecipeCard: View {
    @ObservedObject var item: RecipeItem
    //    @Binding var image: Image
    var body: some View {
        //        ZStack {
        Card(title: item.name ,hasBorder: true, hasShadow: false, leading: {
            //                            Text("wowzers")
            
            ImageContainer(image: $item.image, size: CGFloat(150.0))
                .cornerRadius(12)
                .shadow(radius: 4)
        }, trailing: {
            // MARK: — Notes Section
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading) {
                        VStack {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.top, 5)
                        Group {
                            Text("- Origin: \(item.cuisine)")
                            ForEach(item.notes, id: \.id) { note in
                                Text("- \(note.text)")
                                    .fontWeight(.light)
                            }
                        }
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.caption)
                        .padding(.leading, 2)
                        Spacer()
                    }
                    
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.yellow.opacity(0.4))
                    
                    HStack {
                        
                        VStack(spacing: 0) {
                            ToggleIconButton(
                                iconOn: .system("star.fill"),
                                iconOff: .system("star"),
                                isDisabled: .constant(false),
                                isSelected: $item.isFavorite) {
                                }
                                .asStandardIconButtonStyle(withColor: .yellow)
                            Text("Favorite")
                                .font(.footnote)
                                .fontWeight(.regular)
                                .padding(0)
                        }
                        if let videoURL = item.videoURL {
                            Spacer()
                            VStack(spacing: 0){
                                IconButton(icon: .system("video.fill"), isDisabled: .constant(false)) {
                                    
                                }
                                .asStandardIconButtonStyle(withColor: .green)
                                Text("Youtube")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .padding(0)
                            }
                        } else {
                            Spacer()
                        }
                        
                        if let sourceSite = item.sourceURL {
                            
                            Spacer()
                            VStack(spacing: 0){
                                IconButton(icon: .system("safari.fill"), isDisabled: .constant(false)) {
                                    
                                }
                                .asStandardIconButtonStyle(withColor: .blue)
                                Text("Web")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .padding(0)
                            }
                        } else {
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    
                }
                .disabled(true)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(0)
            }
        })
    }
}
