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
    @State private var feedbackMessage: String = ""
    @State private var feedbackOnLoading: FeedbackType = .stable
    
    init(defaultSize: ImageSize = .medium, vm: RecipesViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        List{
            if feedbackOnLoading.isStable {
                Section(header: searchHeaderView) {
                    ForEach(vm.items, id: \.id) { item in
                        FavoriteRecipeCard(viewmodel: FavoriteFecipeRowViewModel(recipeId: item.id, memoryStore: vm.recipeStore)) {
                            nav.path2.append(.recipeDetail(item.id))
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .listRowBackground(Color.clear)
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
//        .animation(.easeInOut, value: vm.items)
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
            do {
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
    @StateObject private var vm: FavoriteFecipeRowViewModel
    
    @State private var clickableLinks: ClickableLinks
    let size: CGSize
    let onTapRow: () -> Void
    
    init(
        viewmodel: FavoriteFecipeRowViewModel,
        size: CGSize = .init(width: 150, height: 150),
        onTapRow: @escaping () -> Void
    ) {
        _vm = StateObject(wrappedValue: viewmodel)
        self.size = size
        self.onTapRow = onTapRow
        self.clickableLinks = ClickableLinks(favorite: viewmodel.isRecipFavorited, youtube: viewmodel.videoURL != nil ? true: false, source: viewmodel.sourceURL != nil ? true: false)
    }
    
    // `ClickableLinks evaluate if any optionable links are availabler per type (i.e. web, favorites...)
    struct ClickableLinks {
        var favorite: Bool
        var youtube: Bool
        var source: Bool
    }
    //    @Binding var image: Image
    var body: some View {
        //        ZStack {
        Card(title: vm.title, hasBorder: true, hasShadow: true, leading: {
            //                            Text("wowzers")
//            VStack {
            ImageCard(image: $vm.image, size: size, hasBorder: true, hasShadow: false)
//                ImageContainer(image: $item.image, size: CGFloat(150.0))
//                    .cornerRadius(12)
//                    .shadow(radius: 4)
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }, trailing: {
            // MARK: — Notes Section
//            VStack {
//                Spacer()
//            EmptyView()
            
            VStack(alignment: .center, spacing: 0) {
                //                    VStack(alignment: .leading) {
                //                        VStack {
                VStack {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    //                        }
                    //                        .padding(.top, 5)
                    Text("Origin: \(vm.description)")
                        .font(.robotoMono.regular(size: 12))
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .overlay(alignment: .bottom) {
//                    VStack {
//                        Spacer()
                        Divider()
                        .frame(height: 0.5)
                            .background(.black.opacity(0.5))
                            .padding(.horizontal, 10)
//                    }
//                    .padding(.top, 20)
                }
                //                    VStack {
                //                        Group {
                //                HStack {
                
                //                        Divider()
                //                                    .frame(width: 1)
                //                            .background(.black.opacity(0.5))
                //                            .padding(.leading, 1)
                //                    ForEach(item.notes, id: \.id) { note in
                //                                Text("-\(note.text)")
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(vm.notes, id: \.id) { note in
                            Text("- \(note)")
                                .font(.robotoMono.regular(size: 12))
                            //                                    .lineLimit(1)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            //                                    .padding(.leading, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    //                            Divider()
                    //                            //                                    .frame(height: 1)
                    //                                .background(.black.opacity(0.5))
                    //                                .padding(.horizontal, 10)
                    //                                    .fontWeight(.light)
                }
                //                }
                //                        }
                //                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//                .background(.red)
                //                }
                //                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                //                        .font(.robotoMono.light(size: 8))
                //                        .padding(.leading, 2)
                //                        Spacer()
                //                    }
                //
                //                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            .frame(height: size.height)
//                .disabled(true)
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(.yellow.opacity(0.4))
                .cornerRadius(16)
                .padding(.trailing, 5)
//                .padding(.vertical, 10)
//                .padding(.trailing, 5)
            
            
//                Spacer()
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }, {
            
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    ToggleIconButton(
                        iconOn: .system("star.fill"),
                        iconOff: .system("star"),
                        isDisabled: vm.isDisabledBinding,
                        isSelected: $vm.isFavoriteBinding) {
                            vm.toggleFavorite()
                        }
                        .asStandardIconButtonStyle(withColor: .yellow)
                    Text("Favorite")
                        .font(.robotoMono.regular(size: 16).bold())
                }
//                        if let videoURL = item.videoURL {
                    Spacer()
                    VStack(spacing: 0){
                        IconButton(icon: .system("video.fill"), isDisabled: .constant(false)) {
                            
                        }
                        .asStandardIconButtonStyle(withColor: .green)
                        Text("Youtube")
                            .font(.robotoMono.regular(size: 16).bold())
//                            .padding(0)
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
                            .font(.robotoMono.regular(size: 16).bold())
                    }
                Spacer()
//                        } else
//                            Spacer()
//                        }
            }
//            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 10))
            
        })
        
            .gesture(TapGesture().onEnded({
                onTapRow()
            }), including: .gesture)
        .task {
            await vm.loadImage(sizeSmall: false)
        }
//        .onAppear {
//            print("were appearing oh yeah")
//            // By having this here we can always show a progressview whenever
//            // we return to this item cell.
//            item.image = nil
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
