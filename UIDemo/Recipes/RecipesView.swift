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
    @State private var badRecipe: BadRecipe = BadRecipe()
    @State private var feedbackMessage: String = ""
    @State private var feedbackOnLoading: FeedbackType = .stable
    
    struct BadRecipe {
        var isBad: Bool = false
        var id: UUID?
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
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        List {
            if feedbackOnLoading.isStable {
                Section(header: searchHeaderView) {
                    ForEach(vm.items, id: \.id) { item in
                        RecipeRowView(item: item, onToggleFavorite: {
                            withAnimation {
                                vm.toggleFavorite(recipeUUID: item.id)
                            }
                        }) {
                            nav.path.append(.recipeDetail(item.id))
                        }
                        .onDisabled(isDisabled: .constant(item.recipe.isInvalid)) {
                            badRecipe.id = item.id
                            badRecipe.isBad.toggle()
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
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
        .animation(.easeInOut, value: vm.items)
        .listStyle(.insetGrouped)
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
                },
                onReset: {
                    vm.searchModel = nil
                    vm.selectedCuisine = nil
                }
            )
        }
        .alert(
            "Failed to load recipe properly",
            isPresented: $badRecipe.isBad,
            presenting: badRecipe.id
        ) { id in
            CTAButtonStack(.horizontal()) {
                CTAButton(title: "Dismiss") {
                    
                }
                .asPrimaryButton()
                CTAButton(title: "View Anyway") {
                    nav.path.append(.recipeDetail(id))
                }
                .asDestructiveButton()
            }
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


// MARK: - Recipes List View
struct FavoriteRecipesView: View {
    @ObservedObject private var vm: RecipesViewModel
    @EnvironmentObject private var nav: AppNavigation
    @State private var feedbackMessage: String = ""
    @State private var feedbackOnLoading: FeedbackType = .stable
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        List{
            if feedbackOnLoading.isStable {
                Section(header: searchHeaderView) {
                    ForEach($vm.items, id: \.id) { $item in
                        FavoriteRecipeCard(item: $item.wrappedValue)
                            .gesture(TapGesture().onEnded({
                                nav.path2.append(.recipeDetail(item.id))
                            }), including: .gesture)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
//                    .listRowBackground(Color.clear)
                }
//                .background(.blue)
//                .listSectionSeparatorTint(.black)
                
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
        .animation(.easeInOut, value: vm.items)
        .listStyle(.plain)
        .navigationTitle("Favorite Recipes")
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
    
    @State private var clickableLinks: ClickableLinks
    
    init(item: RecipeItem) {
        self.item = item
        self.clickableLinks = ClickableLinks(youtube: item.videoURL != nil ? true: false, source: item.sourceURL != nil ? true: false)
    }
    
    // `ClickableLinks evaluate if any optionable links are availabler per type (i.e. web, favorites...)
    struct ClickableLinks {
        let favorite: Bool = false
        var youtube: Bool
        var source: Bool
    }
    //    @Binding var image: Image
    var body: some View {
        //        ZStack {
        Card(title: item.name ,hasBorder: true, hasShadow: false, leading: {
            //                            Text("wowzers")
            VStack {
                ImageContainer(image: $item.image, size: CGFloat(150.0))
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }, trailing: {
            // MARK: — Notes Section
//            VStack {
//                Spacer()
                VStack(alignment: .center, spacing: 0) {
//                    VStack(alignment: .leading) {
//                        VStack {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
//                                .frame(maxWidth: .infinity, alignment: .center)
//                        }
//                        .padding(.top, 5)
                        Group {
                            Text("- Origin: \(item.cuisine)")
                            ForEach(item.notes, id: \.id) { note in
                                Text("- \(note.text)")
                                    .fontWeight(.light)
                            }
                        }
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.robotoMono.light(size: 8))
//                        .padding(.leading, 2)
//                        Spacer()
//                    }
//
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                }
                .disabled(true)
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(.yellow.opacity(0.4))
                .cornerRadius(12)
//                Spacer()
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }, {
            
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
                        .font(.robotoMono.regular(size: 10))
                }
//                        if let videoURL = item.videoURL {
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
//                        } else {
//                            Spacer()
//                        }
                
//                        if let sourceSite = item.sourceURL {
                    
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
//                        } else {
//                            Spacer()
//                        }
            }
//            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            
        })
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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

#if DEBUG
struct FavoriteRecipesCard_Previews: PreviewProvider {
    @State var strring = "https%3A//d3jbb8n5wk0qxi.cloudfront.net/photos/.../small.jpg"
    
    static var previews: some View {
        @StateObject var recipeStore = RecipeStore()
        @StateObject var vm = RecipesViewModel(memoryStore: RecipeDataSource.shared, recipeStore: recipeStore, filterStrategy: FavoriteRecipesFilter())
        @StateObject var nav = AppNavigation.shared
        
        @StateObject var themeManager: ThemeManager = ThemeManager()
        // TODO: Test resizing here later.
        
        FavoriteRecipeCard(item: RecipeItem(recipe: Recipe.recipePreview(using: .good)!))
            .background(.red)
            .environmentObject(themeManager)
        

    }
}
#endif


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
        NavigationStack {
            RecipesView(vm: vm)
                .environmentObject(themeManager)
                .environmentObject(nav)
        }
    }
}
#endif

