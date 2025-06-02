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
    @ObservedObject private var vm: RecipesViewModel // = RecipesViewModel()
//    @State var imageSize: Constants.ImageSize
    //    @EnvironmentObject private var themeManager: ThemeManager
    
    init(defaultSize: Constants.ImageSize = .medium,
         vm: RecipesViewModel
    ) {
//        _ = FetchCache.shared
//        self.imageSize = defaultSize
        _ = FetchCache.shared
        self.vm = vm // StateObject(wrappedValue: RecipesViewModel())
    }
    
    var body: some View {
        List(vm.items, id: \.id) { item in
            RecipeRowView(item: item)
//                    .padding(0)
//                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(.red)
            .listRowInsets(EdgeInsets())
//            .background(.green)
        }
        .onAppear {
            print("list element appeared")
            vm.loadRecipes()
        }
//        .onTapGesture {
//            Task {
//                FetchCache.shared.refresh()
//            }
//        }
//        List(vm.items, id: \.id ) { recipeItem in
//            
//            recipeItem.daImage
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(width: 50,
//                       height: 50)
//                .background(.gray.opacity(0.5))
//                .clipped()
//                .task {
//            print("fasafsdfasdf")
//                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
//                    
//            recipeItem.image = Image(systemName: "person")
////                    await vm.getRecipeImage(for: recipeItem)
////                            guard let url = sourceURL else { return }
////
////                            do {
////                                if let image = try await FetchCache.shared.getImage(url: url) {
////                                    self.image = image
////                                } else {as
////                                    return
////                                }
////                            } catch {
////                                image = themeManager.imageAssetManager.getImage(imageIdentifier: .preset(.imageNotFound))
////                                return
////                            }
//        }
//            
//////            NavigationLink(value: Route.recipeDetail(recipeItem.wrappedValue.recipe)) {
////                FeatureItem(
////                    title: recipeItem.name, // wrappedValue.name,
////                    description: "recipeItem.wrappedValue.cuisine",
////                    leading: {
//////                        VStack {
////                            recipeItem.daImage
////                                .resizable()
////                                .aspectRatio(contentMode: .fill)
////                                .frame(width: 50,
////                                       height: 50)
////                                .background(.gray.opacity(0.5))
////                                .clipped()
//////                        }
//////                        ImageContainer(
//////                            image: recipeItem.image
////////                                Binding(
////////                                get: { recipeItem.image },
////////                                set: { value in
////////                                    recipeItem.image = value
////////                                }
////////                            )
//////                            ,
//////                            //                            image: <pass image>,
//////                            size: $imageSize,
//////                            accessibilityId: recipeItem.id)
////                                .task {
////                            print("fasafsdfasdf")
////                            recipeItem.image = Image(systemName: "person")
////                                    recipeItem.objectWillChange.send()
////        //                    await vm.getRecipeImage(for: recipeItem)
////        //                            guard let url = sourceURL else { return }
////        //
////        //                            do {
////        //                                if let image = try await FetchCache.shared.getImage(url: url) {
////        //                                    self.image = image
////        //                                } else {as
////        //                                    return
////        //                                }
////        //                            } catch {
////        //                                image = themeManager.imageAssetManager.getImage(imageIdentifier: .preset(.imageNotFound))
////        //                                return
////        //                            }
////                        }
////                    }
////                )
////                .frame(maxWidth: .infinity, maxHeight: 100)
//                
////            }
//            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
//        }
//        
//        .listStyle(.automatic)
//        .listRowSpacing(10)
//        .navigationTitle("Recipes")
//        .background(Color.gray.opacity(0.5))
//        .refreshable {
//            FetchCache.shared.refresh()
//        }
//        .onAppear {
//            vm.loadRecipes()
//        }
    }
    
    struct RecipeRowView: View {
        // Suppose the parent passed us a Binding<RecipeItem>:
        @ObservedObject var item: RecipeItem

        var body: some View {
            HStack(spacing: 0) {
//                Group {
//                    if let image = item.image {
                        VStack {
                            item.image
//                                .image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .task {
                                    print("// Write through the binding:")
                                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                    print("asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfa")
                                    item.image = Image(systemName: "heart.fill")
                                }
                        }
                        .padding()
//                        .background(.black)
                        .onAppear {
                            print("image vtack in place")
                        }
//                    }
                Text("\(item.name)")
                        .padding()
                        .onAppear {
                            print("well textbox shows")
                        }
//                }
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
        
//        NavigationStack {
        RecipesView(vm: vm)
                .environmentObject(themeManager)
//        }
    }
}
#endif
