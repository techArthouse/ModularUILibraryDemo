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
//        @State var image: Image?
        @EnvironmentObject private var nav: AppNavigation
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        var body: some View {
            
            FeatureItem(
                title: item.name,
                description: item.cuisine,
                action: {
                    nav.path.append(.recipeDetail(item.recipe))
                },
                leading: {
                    ImageContainer(image: $item.image, size: dynamicTypeSize.photoDimension, accessibilityId: item.id)
                })
            .task {
                do {
                    guard let url = item.smallImageURL else {
                        throw URLError(.badURL)
                    }
                    item.image = try await FetchCache.shared.getImageFor(url: url)
                } catch let e as FetchCacheError {
                    switch e {
                    case .taskCancelled:
                        // We anticipate to fall here with a CancellationError as that is what's thrown when `task
                        // cancels a network call. but we wrap it in our own error.
                        // In our case we scrolled and the row running the request disappeared.
                        return
                    default:
                        // Any other error that would suggest we are still viewing the row but an error occured
                        print("Image load failed: \(e.localizedDescription)")
                        item.image = Image("imageNotFound")
                    }
                } catch let e {
                    // Any error we haven't anticipated
                    // (but it's not likely to happen since the methods define the throw type)
                    print("Error in row task. error: \(e.localizedDescription)")
                    item.image = Image("placeHolder")
                }
            }
            .onAppear {
                // By having this here we can always show a progressview whenever
                // we return to this item cell.
                item.image = nil
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
