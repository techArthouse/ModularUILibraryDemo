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
    
    init(defaultSize: Constants.ImageSize = .medium,
         vm: RecipesViewModel
    ) {
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
            await FetchCache.shared.refresh()
        }
        .task {
            print("list element appeared")
            
            do {
                // Pick the correct folder name: "DevelopmentFetchImageCache" "FetchImageCache"
            #if DEBUG
                try vm.startCache(path: "DevelopmentFetchImageCache")
            #else
                try vm.startCache(path: "FetchImageCache")
            #endif
            } catch {
                return
                // failed to start cache. what do i do here? is vm.items = [] appropriate?
            }
            await vm.loadRecipes()
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
                        return // our only safe exit
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
    @State var strring = "https%3A//d3jbb8n5wk0qxi.cloudfront.net/photos/.../small.jpg"
    
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
