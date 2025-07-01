//
//  RecipesView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
//import Combine
import ModularUILibrary

// MARK: - Recipes List View
struct RecipesView: View {
    @ObservedObject private var vm: RecipesViewModel
    @EnvironmentObject private var nav: AppNavigation
//    @EnvironmentObject private var memoryStore: RecipeMemoryDataSource
    @State private var feedbackMessage: String = ""
    @State private var feedbackOnLoading: FeedbackType = .stable
    @State private var totalItems = 0
    
    enum FeedbackType {
        case stable, error, emptyList
        
        var isError: Bool {
            self == .error
        }
        
        var isStable: Bool {
            self == .stable
        }
    }
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if feedbackOnLoading.isStable {
//                    Section(header: searchHeaderView) {
                    searchHeaderView
                        Divider()
                            .frame(height: 1)
                            .background(.black.opacity(0.5))
                        //                            .padding(.horizontal, 20)
                        ForEach(vm.items, id: \.id) { item in
//                            withAnimation {
//                                Group {
                                    if item.selected {
                                        RecipeRowView(viewmodel: RecipeRowViewModel(recipeId: item.id, recipeStore: vm.recipeStore, vm: vm)) {
                                            nav.path.append(.recipeDetail(item.id))
                                        }
                                        .transition(.asymmetric(
                                                     insertion: .opacity,
                                                     removal: .move(edge: .trailing))
                                        )
//                                        .transition(.asymmetric(insertion: .slide, removal: .move(edge: .trailing)))
                                        //                            .shadow(radius: 1)
                                        //                                                            .animation(.linear, value: item.selected)
                                        
//                                        Divider()
//                                            .frame(height: 1)
//                                            .background(.black.opacity(0.3))
//                                            .padding(.horizontal, 15)
                                        //                        .listRowInsets(EdgeInsets())
                                        //                        .border(.black, width: 1)
                                    }
                                    
//                                }
//                                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing)))
//                                .animation(.linear, value: item.selected)
//                            }
//                            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing)))
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 3)
                        //                    .listRowSeparator(.hidden)
                        //                        .listRowSeparatorTint(.black, edges: .all)
                        //                        .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                        //                    .listRowBackground(Color(.systemGray))
                        //                    .listRowSpacing(10)
//                    }
                    //                    .background(.white)
                    //                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    //                .frame(maxWidth: .infinity)
                } else {
                    VStack {
                        Text(feedbackMessage)
                            .font(.robotoMono.regular(size: 25.0))
                            .multilineTextAlignment(.center)
                            .bold()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .background(feedbackOnLoading.isError ? .red.opacity(0.3): .blue.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            //            .padding(.top, 5)
            .padding(.vertical, 5)
            .padding(.horizontal, 5)
            .background{
                RoundedRectangle(cornerRadius: 0)
                    .fill(.gray.opacity(0.09))
                    .shadow(color: .black, radius: 1)
                
            } //            .background(Color(.systemGray).opacity(0.6))
            .cornerRadius(4)
            .animation(.easeInOut, value: vm.items.map(\.selected))
            //            .animation(.easeInOut, value: vm.items)
        }
//        .animation(.linear, value: vm.items)
//        .listStyle(.plain)
        .navigationTitle("Recipes")
        .refreshable {
            do {
                if try await vm.reload() {
                    print("task finished RecipesView")
                } else {
                    feedbackMessage = "There was an error loading. Pull to refresh and try again."
                    feedbackOnLoading = .error
                }
            } catch {
                print("Cache failed to start")
                feedbackMessage = "There was an error loading. Pull to refresh and try again."
                feedbackOnLoading = .error
                return
            }
        }
        .task {
            do {
#if DEBUG
                try vm.startCache(path: "DevelopmentFetchImageCache")
#else
                try vm.startCache(path: "FetchImageCache")
#endif
                if try await vm.loadRecipes() {
                    print("task finished RecipesView")
                } else {
                    feedbackMessage = "There was an error loading. Pull to refresh and try again."
                    feedbackOnLoading = .error
                }
            } catch let error as FetchCacheError {
                switch error {
                case .directoryAlreadyOpenWithPathComponent:
                    print("Cache already exists")
                default:
                    break
                }
            } catch {
                print("Cache failed to start")
                feedbackMessage = "There was an error loading. Pull to refresh and try again."
                feedbackOnLoading = .error
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
                    vm.filterSend()
                },
                onReset: {
                    vm.searchModel = nil
                    vm.selectedCuisine = nil
                }
            )
        }
//        .alert(
//            "Failed to load recipe properly",
//            isPresented: $badRecipe.isBad,
//            presenting: badRecipe.id
//        ) { id in
//            CTAButtonStack(.horizontal()) {
//                CTAButton(title: "Dismiss") {
//                    
//                }
//                .asPrimaryButton()
//                CTAButton(title: "View Anyway") {
//                    nav.path.append(.recipeDetail(id))
//                }
//                .asDestructiveButton()
//            }
//        }
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
        .background(Color(.systemGray6))
        .border(.black, width: 0.5)
    }
}

enum FeedbackType {
    case stable, error, emptyList
    
    var isError: Bool {
        self == .error
    }
    
    var isStable: Bool {
        self == .stable
    }
}

//#if DEBUG
//struct FavoriteRecipesCard_Previews: PreviewProvider {
//    @State var strring = "https%3A//d3jbb8n5wk0qxi.cloudfront.net/photos/.../small.jpg"
//    
//    static var previews: some View {
//        @StateObject var recipeStore = RecipeStore()
//        @StateObject var vm = RecipesViewModel(memoryStore: RecipeDataSource.shared, recipeStore: recipeStore, filterStrategy: FavoriteRecipesFilter())
//        @StateObject var nav = AppNavigation.shared
//        
//        @StateObject var themeManager: ThemeManager = ThemeManager()
//        // TODO: Test resizing here later.
//        
//        FavoriteRecipeCard(item: RecipeItem(recipe: Recipe.recipePreview(using: .good)!))
//            .background(.red)
//            .environmentObject(themeManager)
//        
//
//    }
//}
//#endif


#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    @State var strring = "https%3A//d3jbb8n5wk0qxi.cloudfront.net/photos/.../small.jpg"
    
    static var previews: some View {
        @StateObject var recipeStore = RecipeStore(memoryStore: RecipeMemoryDataSource.shared, fetchCache: MockFetchCache())
        @StateObject var vm = RecipesViewModel(recipeStore: recipeStore, filterStrategy: AllRecipesFilter())
//        @StateObject var vm2 = RecipesViewModel(memoryStore: RecipeDataSource.shared, recipeStore: recipeStore, filterStrategy: AllRecipesFilter())
        @StateObject var nav = AppNavigation.shared
        
        @StateObject var themeManager: ThemeManager = ThemeManager()
        // TODO: Test resizing here later.
        
//        NavigationStack {
//            FavoriteRecipesView(vm: vm2)
//                .environmentObject(themeManager)
//                .environmentObject(nav)
//        }
        
        NavigationStack {
            RecipesView(vm: vm)
                .environmentObject(themeManager)
                .environmentObject(nav)
//                .environmentObject(RecipeMemoryDataSource.shared)
        }
    }
}
#endif

class MockFetchCache: ImageCache {
    func refresh() async {
        print("refreshing")
    }
    
    func openCacheDirectoryWithPath(path: String) throws(FetchCacheError) {
        print("mock fetchcache directory opened")
    }
    
    func getImageFor(url networkSourceURL: URL) async throws(FetchCacheError) -> Image {
        Image(systemName: "heart.fill")
            .resizable()
            .renderingMode(.template)
    }
}
