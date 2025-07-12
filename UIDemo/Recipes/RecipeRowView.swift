//
//  RecipeRowView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/16/25.
//


import SwiftUI
import ModularUILibrary

/// Takes up as much width and height as it can. specify size if you need different.
struct RecipeRowView: View {
    @StateObject private var vm: RecipeRowViewModel
    let config: FeatureItemConfig
    @State private var badRecipe: Bool = false
//    @State private var isSelected = false
    
    struct BadRecipe {
        var isBad: Bool = false
        var id: UUID?
    }
    // Suppose the parent passed us a Binding<RecipeItem>:
//    @ObservedObject var item: RecipeItem
    let onTapRow: () -> Void
    @EnvironmentObject private var nav: AppNavigation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        
    init(
        viewmodel: RecipeRowViewModel,
        config: FeatureItemConfig = .init(rounded: true, withBorder: false),
        onTapRow: @escaping () -> Void
    ) {
        _vm = StateObject(wrappedValue: viewmodel)
        self.config = config
        self.onTapRow = onTapRow
    }
    
    var body: some View {
        
        FeatureItem(
            title: vm.title,
            description: vm.description,
            isDisabled: vm.isDisabledBinding.wrappedValue,
            config: config,
            action: {
                print("FeatureItem: \(vm.title) row tapped")
                onTapRow()
            },
            leading: {
                ImageContainer(image: vm.image, size: dynamicTypeSize.photoDimension, accessibilityId: vm.recipeId.uuidString)
                    .equatable()
                    .border(.black.opacity(0.5), width: 1)
                    .onAppear{
                        print("i appear imagecontainer with image \(vm.image != nil)")
                    }
            },
            trailing: {
                if vm.isNotValid {
                    EmptyView()
                } else {
                    ToggleIconButton(
                        iconOn: .system("star.fill"),
                        iconOff: .system("star"),
                        isDisabled: vm.isDisabledBinding, // .constant(false),
                        isSelected: .constant(vm.isRecipFavorited)) {
                            vm.toggleFavorite()
                            //                        vm.isFavoriteBinding.wrappedValue = true
                        }
                        .asStandardIconButtonStyle(withColor: .yellow)
                        .accessibilityLabel(Text("ToggleIconButton: \(vm.recipeId.uuidString)"))
                }
            })
        
        .onDisabled(isDisabled: vm.isDisabledBinding) {
            badRecipe.toggle()
        }
        .task {
            await vm.load()
        }
        .alert(
            "Failed to load recipe properly",
            isPresented: $badRecipe
        ) {
            CTAButtonStack(.horizontal()) {
                CTAButton(title: "Dismiss") {
                    
                }
                .asPrimaryButton()
                CTAButton(title: "View Anyway") {
                    onTapRow()
                }
                .asDestructiveButton()
            }
        }
    }
}

#if DEBUG

struct RecipeRowView_Previews: PreviewProvider {
    static var previews: some View {
        let goodRecipe = Recipe.recipePreview(using: .good).first!
//        let recipeStore = RecipeStore(memoryStore: RecipeDataSource.shared)
        let recipeStore = RecipeStore(memoryStore: MockRecipeMemoryDataSource(), fetchCache: MockFetchCacheGOODandBAD())
        let invalidRecipe = Recipe.recipePreview(using: .malformed)[1]
        
        let goodItem = RecipeItem(goodRecipe)
//        goodItem.image = Image(systemName: "photo") // Simulate image already loaded
        
        let badItem = RecipeItem(invalidRecipe)
//        badItem.image = Image(systemName: "exclamationmark.triangle") // Placeholder for failed load
        
        let nav = AppNavigation.shared
        let themeManager = ThemeManager()
        recipeStore.loadRecipes(recipes: [goodRecipe, invalidRecipe])
        
        return VStack {
            RecipeRowView(viewmodel: RecipeRowViewModel(recipeId: goodItem.id, recipeStore: recipeStore)) {
                print("Tapped row with goodItem")
            }
            .background(.red)
            .previewDisplayName("Good Recipe")
            .environmentObject(nav)
            .environmentObject(themeManager)
            
            RecipeRowView(viewmodel: RecipeRowViewModel(recipeId: badItem.id, recipeStore: recipeStore)) {
                print("Tapped row with badItem")
            }
            .background(.red)
            .previewDisplayName("Invalid Recipe")
            .environmentObject(nav)
            .environmentObject(themeManager)
        }
    }
}

class MockFetchCacheGOODandBAD: ImageCache {
    func loadImage(for url: URL) async -> Result<Image, FetchCacheError> {
        if url.absoluteString != "https://d3jbb8n5wk0qxi.cloudfront.net/photos/b9ab0071-b281-4bee-b361-ec340d405320/small.jpg" {
            return
                .failure(.failedToFetchImageFrom(source: url, withError: .failedToFindImageFromSystemMemoryBanks))
        } else {
            return
                .success(
                    Image(systemName: "heart.fill")
                    .resizable()
                    .renderingMode(.template))
        }
    }
    
    func refresh() async {
        print("refreshing")
    }
    
    func openCacheDirectoryWithPath(path: String) throws(FetchCacheError) {
        print("mock fetchcache directory opened")
    }
}
#endif

class MockRecipeMemoryDataSource: RecipeMemoryStoreProtocol, ObservableObject {
    @Published var memories: [UUID : RecipeMemory] = [:]
    
    func getMemory(for recipeUUID: UUID) -> RecipeMemory {
        if let res = memories[recipeUUID] {
            return res
        } else {
            return RecipeMemory(isFavorite: false, notes: [])
        }
    }
    
    func isFavorite(for recipeUUID: UUID) -> Bool {
        
        getMemory(for: recipeUUID).isFavorite
    }
    
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) {
        if var mem = memories[recipeUUID] {
            mem.isFavorite = favorite
            memories[recipeUUID] = mem
        } else if favorite {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
    }
    
    func notes(for recipeUUID: UUID) -> [RecipeNote] {
        [RecipeNote(id: UUID(), text: "this is one note", date: Date())]
    }
    
    func addNote(_ text: String, for recipeUUID: UUID) -> RecipeNote? {
        nil
    }
    
    func deleteNotes(for recipeUUID: UUID) {
        //
    }
    
    func toggleFavorite(recipeUUID: UUID) {
        if var mem = memories[recipeUUID] {
            mem.isFavorite.toggle()
            memories[recipeUUID] = mem
        } else {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
    }
}
