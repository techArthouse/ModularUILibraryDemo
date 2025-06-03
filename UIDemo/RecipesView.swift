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
//    @State var imageSize: Constants.ImageSize
    //    @EnvironmentObject private var themeManager: ThemeManager
    
    init(defaultSize: Constants.ImageSize = .medium,
         vm: RecipesViewModel
    ) {
//        _ = FetchCache.shared
//        self.imageSize = defaultSize
        _ = FetchCache.shared
        self.vm = vm
    }
    
    var body: some View {
        List(vm.items, id: \.id) { item in
            RecipeRowView(item: item)
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.automatic)
        .listRowSpacing(10)
        .navigationTitle("Recipes")
        .refreshable {
            FetchCache.shared.refresh()
        }
        .onAppear {
            print("list element appeared")
            vm.loadRecipes()
        }
    }
    
    struct RecipeRowView: View {
        // Suppose the parent passed us a Binding<RecipeItem>:
        @ObservedObject var item: RecipeItem
        @State var image: Image?

        var body: some View {
            
            FeatureItem(
                title: item.name,
                description: item.cuisine,
                leading: {
                    ImageContainer(image: image, accessibilityId: item.id)
                })
            .task {
                do {
                    guard let url = item.smallImageURL else {
                        throw URLError(.badURL)
                    }
                    print(item.id)
                    if let i = try await FetchCache.shared.getImageFor(url: url) {
                        image = i
                    }
                } catch {
                    print(error.localizedDescription)
                }
                // we make it here then we never got an image
                image = Image("imageNotFound")
            }
            .onAppear {
                image = nil // right now i think that by having this here we can always show a progressview when we
                // return to this item cell in case it was canceled before the image return the first time.
            }
        }
    }
}


#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var vm = RecipesViewModel()
        let themeManager: ThemeManager = ThemeManager()
        // TODO: Test resizing here later.
        
        NavigationStack {
            RecipesView(vm: vm)
                .environmentObject(themeManager)
        }
    }
}
#endif
