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
    let onTapRow: () -> Void
    
    @State private var badRecipe: Bool = false
    @EnvironmentObject private var nav: AppNavigation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        
    init(
        makeRecipeRowVM: @escaping () -> RecipeRowViewModel,
        config: FeatureItemConfig = .init(rounded: true, withBorder: false),
        onTapRow: @escaping () -> Void
    ) {
        _vm = StateObject(wrappedValue: makeRecipeRowVM())
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
                Logger.log("FeatureItem: \(vm.title) row tapped")
                onTapRow()
            },
            leading: {
                ImageContainer(image: vm.image, size: dynamicTypeSize.photoDimension, accessibilityId: vm.accessibilityId)
                    .equatable()
                    .border(.black.opacity(0.5), width: 1)
                    .onAppear{
                        Logger.log("i appear imagecontainer with image \(vm.image != nil)")
                    }
            },
            trailing: {
                if !vm.isValid {
                    EmptyView()
                } else {
                    ToggleIconButton(
                        iconOn: .system("star.fill"),
                        iconOff: .system("star"),
                        isDisabled: vm.isDisabledBinding,
                        isSelected: vm.isFavoriteBinding)
                    .asStandardIconButtonStyle(withColor: .yellow)
                    .accessibilityLabel(Text("ToggleIconButton: \(vm.accessibilityId)"))
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

// MARK: - DEBUG Structures/Previews

#if DEBUG

struct RecipeRowView_Previews: PreviewProvider {
    static var previews: some View {
        let goodRecipe = Recipe.recipePreview(using: .good).first!
//        let recipeStore = RecipeStore(memoryStore: RecipeDataSource.shared)
        let recipeStore = RecipeDataService(memoryStore: MockRecipeMemoryDataSource(), fetchCache: MockFetchCacheGOODandBAD())
        let invalidRecipe = Recipe.recipePreview(using: .malformed)[1]
        
        let goodItem = RecipeItem(goodRecipe)
//        goodItem.image = Image(systemName: "photo") // Simulate image already loaded
        
        let badItem = RecipeItem(invalidRecipe)
//        badItem.image = Image(systemName: "exclamationmark.triangle") // Placeholder for failed load
        
        let nav = AppNavigation.shared
        let themeManager = ThemeManager()
        recipeStore.setRecipes(recipes: [goodRecipe, invalidRecipe])
        
        return VStack {
            RecipeRowView(makeRecipeRowVM: { RecipeRowViewModel(recipeId: goodItem.id, recipeStore: recipeStore, imageSize: .small)} ) {
                Logger.log("Tapped row with goodItem")
            }
            .background(.red)
            .previewDisplayName("Good Recipe")
            .environmentObject(nav)
            .environmentObject(themeManager)
            
            RecipeRowView(makeRecipeRowVM: { RecipeRowViewModel(recipeId: badItem.id, recipeStore: recipeStore, imageSize: .small)} ) {
                Logger.log("Tapped row with badItem")
            }
            .background(.red)
            .previewDisplayName("Invalid Recipe")
            .environmentObject(nav)
            .environmentObject(themeManager)
        }
    }
}

class MockFetchCacheGOODandBAD: ImageCacheProtocol {
    
    func loadImage(for url: URL) async -> Result<Image, ImageCacheError> {
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
        Logger.log(tag: "MockFetchCache", "refreshing")
    }
    
    func ensureCacheDirectoryExists() throws(ImageCacheError) {
        // nothing yet
    }
}

class MockRecipeMemoryDataSource: RecipeMemoryDataSourceProtocol {
    var notes = [RecipeNote(id: UUID(), text: "this is one note", date: Date())]
    func deleteNote(for recipeUUID: UUID, noteId: UUID) {
        notes.removeAll(where: {$0.id == noteId})
    }
    
    func load() {
        // nothing yet
    }
    
    func save() {
        // nothing yet
    }
    
    func addNote(_ text: String, for recipeUUID: UUID) {
        self.notes.append(RecipeNote(id: UUID(), text: text, date: Date()))
    }
    
    @Published var memories: [UUID : RecipeMemory] = [:]
    
    func getMemory(for recipeUUID: UUID) -> RecipeMemory {
        if let res = memories[recipeUUID] {
            return res
        } else {
            return RecipeMemory(isFavorite: true, notes: [])
        }
    }
    
    func isFavorite(for recipeUUID: UUID) -> Bool {
        
        getMemory(for: recipeUUID).isFavorite
    }
    
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) {
        if let mem = memories[recipeUUID] {
            mem.isFavorite = favorite
            memories[recipeUUID] = mem
        } else if favorite {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
    }
    
    func notes(for recipeUUID: UUID) -> [RecipeNote] {
        self.notes
    }
    
    func addNote(_ text: String, for recipeUUID: UUID) -> RecipeNote? {
        nil
    }
    
    func deleteNotes(for recipeUUID: UUID) {
        //
    }
    
    func toggleFavorite(recipeUUID: UUID) {
        if let mem = memories[recipeUUID] {
            mem.isFavorite.toggle()
            memories[recipeUUID] = mem
        } else {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
    }
}

#endif
