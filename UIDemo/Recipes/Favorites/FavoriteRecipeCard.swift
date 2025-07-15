//
//  FavoriteRecipeCard.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/11/25.
//

import SwiftUI
import ModularUILibrary

/// This is a view that uses Card views to display a recipe that has been favorited in more detail than the regular list.
/// The View is larger to display the larger jpg and also features feedback as to which links are available (for example,
/// a link could be missing or did not evaluate to a usable object). Each FavoriteRecipeCard manages its VM lifecycle.
struct FavoriteRecipeCard: View {
    @StateObject private var vm: RecipeRowViewModel
    @State private var clickableLinks: ClickableLinks
    
    let size: CGSize // Size of Image in `ImageCard`
    let onTapRow: () -> Void
    
    /// `ClickableLinks` evaluate if any optionable links are availabler per type (i.e. web, favorites...)
    struct ClickableLinks {
        var favorite: Bool
        var youtube: Bool
        var source: Bool
    }
    
    init(viewmodel: RecipeRowViewModel,
         size: CGSize = .init(width: 150, height: 150),
         onTapRow: @escaping () -> Void
    ) {
        _vm = StateObject(wrappedValue: viewmodel)
        self.size = size
        self.onTapRow = onTapRow
        self.clickableLinks = ClickableLinks(favorite: viewmodel.isRecipFavorited,
                                             youtube: viewmodel.videoURL != nil ? true: false,
                                             source: viewmodel.sourceURL != nil ? true: false)
    }
    
    var body: some View {
        Card(
            title: vm.title,
            hasBorder: true,
            hasShadow: true,
            leading: {
                ImageCard(image: vm.image, size: size, hasBorder: true, hasShadow: false)
            },
            trailing: {
                // MARK: — Notes Section
                VStack(alignment: .center, spacing: 0) {
                    VStack {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Origin: \(vm.description)")
                            .font(.robotoMono.regular(size: 12))
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(alignment: .bottom) {
                        Divider()
                            .frame(height: 0.5)
                            .background(.black.opacity(0.5))
                            .padding(.horizontal, 10)
                    }
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(vm.notes, id: \.id) { note in
                                Text("- \(note.text)")
                                    .font(.robotoMono.regular(size: 12))
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                .frame(height: size.height)
                .background(.yellow.opacity(0.4))
                .cornerRadius(16)
                .padding(.trailing, 5)
            },
            {
                // MARK: - Favorite togglable icon
                
                /// This HStack shows icons for each of the recipes clickable links and favorite icon. If the link
                /// is not clickable for any reason then it is disabled and reflects a disabled state.
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        ToggleIconButton(
                            iconOn: .system("star.fill"),
                            iconOff: .system("star"),
                            isDisabled: vm.isDisabledBinding,
                            isSelected: vm.isFavoriteBinding) {
                            }
                            .asStandardIconButtonStyle(withColor: .yellow)
                        Text("Favorite")
                            .font(.robotoMono.regular(size: 16).bold())
                    }
                    
                    Spacer()
                    VStack(spacing: 0){
                        IconButton(icon: .system("video.fill"), isDisabled: .constant(false)) { }
                            .asStandardIconButtonStyle(withColor: .green)
                        
                        Text("Youtube")
                            .font(.robotoMono.regular(size: 16).bold())
                    }
                    Spacer()
                    
                    VStack(spacing: 0){
                        IconButton(icon: .system("safari.fill"), isDisabled: .constant(false)) { }
                            .asStandardIconButtonStyle(withColor: .blue)
                        
                        Text("Web")
                            .font(.robotoMono.regular(size: 16).bold())
                    }
                    Spacer()
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 10))
            })
        .gesture(TapGesture().onEnded({ onTapRow() }), including: .gesture)
        .task {
            await vm.load()
        }
    }
}

#if DEBUG
struct FavoriteRecipesCard_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var recipeStore = RecipeDataService(memoryStore: MockRecipeMemoryDataSource(), fetchCache: MockFetchCache())
        @StateObject var vm = RecipesViewModel(recipeStore: recipeStore, filterStrategy: AllRecipesFilter())
        @StateObject var nav = AppNavigation.shared
        
        @StateObject var themeManager: ThemeManager = ThemeManager()
        // TODO: Test resizing here later.
        
        FavoriteRecipeCard(viewmodel: RecipeRowViewModel(recipeId: UUID(), recipeStore: recipeStore)) {
            print("row tapped")
        }
        .environmentObject(themeManager)
    }
}
#endif
