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
                ImageContainer(image: $vm.image, size: dynamicTypeSize.photoDimension, accessibilityId: vm.recipeId.uuidString)
                    .equatable()
                    .border(.black.opacity(0.5), width: 1)
                    .onAppear{
                        print("i appear imagecontainer with image \(vm.image != nil)")
                    }
            },
            trailing: {
                ToggleIconButton(
                    iconOn: .system("star.fill"),
                    iconOff: .system("star"),
                    isDisabled: .constant(false),
                    isSelected: .constant(vm.isRecipFavorited)) {
                        vm.toggleFavorite()
//                        vm.isFavoriteBinding.wrappedValue = true
                    }
                    .asStandardIconButtonStyle(withColor: .yellow)
                    .accessibilityLabel(Text("ToggleIconButton: \(vm.recipeId.uuidString)"))
            })
        
        .onDisabled(isDisabled: vm.isDisabledBinding) {
            badRecipe.toggle()
        }
        .task {
//            self.isSelected = vm.isFavoriteBinding.wrappedValue
            await vm.loadImage(sizeSmall: true)
        }
        .onAppear {
            print("were appearing oh yeah")
            vm.onAppear()
//            // By having this here we can always show a progressview whenever
//            // we return to this item cell.
//            item.image = nil
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
        let goodRecipe = Recipe.recipePreview(using: .good)!
//        let recipeStore = RecipeStore(memoryStore: RecipeDataSource.shared)
        let recipeStore = RecipeStore(memoryStore: MockRecipeMemoryDataSource(), fetchCache: MockFetchCache())
        let invalidRecipe = Recipe.recipePreview(using: .malformed)!
        
        let goodItem = RecipeItem(goodRecipe)
//        goodItem.image = Image(systemName: "photo") // Simulate image already loaded
        
        let badItem = RecipeItem(invalidRecipe)
//        badItem.image = Image(systemName: "exclamationmark.triangle") // Placeholder for failed load
        
        let nav = AppNavigation.shared
        let themeManager = ThemeManager()
        recipeStore.loadRecipes(recipes: [goodRecipe])
        
        return VStack {
            RecipeRowView(viewmodel: RecipeRowViewModel(placeholder: Image(systemName: "photo"), recipeId: goodItem.id, recipeStore: recipeStore)) {
                print("Tapped row with goodItem")
            }
//            .task {
//                recipeStore.loadRecipes(recipes: [goodRecipe])
//                print("allitems content should have goodRecipe which is \(goodRecipe)")
//                print("\(recipeStore.allItems.first)")
//            }
//            .onAppear {
//            }
            .background(.red)
//            .border(.blue, width: 2)
            .previewDisplayName("Good Recipe")
//            .padding()
//            .previewLayout(.sizeThatFits)
            .environmentObject(nav)
            .environmentObject(themeManager)
            
//            RecipeRowView(viewmodel: RecipeRowViewModel(placeholder: Image(systemName: "exclamationmark.triangle"), recipeId: badItem.id, memoryStore: recipeStore)) {
//                print("Tapped row with badItem")
//            }
////            .frame(maxWidth: .infinity, maxHeight: 100)
//            .background(.red)
//            .previewDisplayName("Invalid Recipe")
////            .padding()
////            .previewLayout(.sizeThatFits)
//            .environmentObject(nav)
//            .environmentObject(themeManager)
////            .preferredColorScheme(.dark)
        }
    }
}
#endif
struct RecipeRowModel: Identifiable {
    let id: UUID
    var show: Bool
    var highlight: Bool // an example
}

class MockRecipeService: RecipeService, ObservableObject {
    func refresh() async {
        print("refresshing")
    }
    
    func startCache(path: String) throws(FetchCacheError) {
        print("Mock started Cache")
    }
    
     var favorite = true
    
    func title(for id: UUID) -> String       { "Mock Title" }
    func description(for id: UUID) -> String { "Mock Cuisine" }
    func isNotValid(for id: UUID) -> Bool       {
        print(" checking valid")
        return false
    }
    func isFavorite(for id: UUID) -> Bool    {
        print("checking favorite")
       return  favorite
    }
    func toggleFavorite(_ id: UUID) {
//        print("toggle to: \()")
        favorite.toggle()
    }
    func notes(for id: UUID) -> [RecipeNote] { [] }
    func addNote(_ text: String, for id: UUID) { }
    func smallImageURL(for id: UUID) -> URL? {
        URL(string: "https://example.com/image.png")
    }
    
    func setFavorite(_ favorite: Bool, for id: UUID) {
        self.favorite = favorite
    }
    
    func deleteNotes(for id: UUID) {
        //
    }
    
    func largeImageURL(for id: UUID) -> URL? {
        URL(string: "https://example.com/image.png")
    }
    
    func sourceWebsiteURL(for id: UUID) -> URL? {
        URL(string: "https://example.com/image.png")
    }
    
    func youtubeVideoURL(for id: UUID) -> URL? {
        URL(string: "https://example.com/image.png")
    }
    
    func getImage(for id: UUID, smallImage: Bool) async throws(FetchCacheError) -> Image? {
        Image(systemName: "heart.fill")
    }
}


//RecipeRowViewModel(id: id,
//                                                    recipeStore: recipeStore,
//                                                    memoryStore: memoryStore)

//@MainActor
//class MockRecipeMemoryStore: RecipeMemoryStoreProtocol {
//    func isFavorite(for recipeUUID: UUID) -> Bool {
//        <#code#>
//    }
//    
//    func notes(for recipeUUID: UUID) -> [RecipeNote] {
//        <#code#>
//    }
//    
//    func addNote(_ text: String, for recipeUUID: UUID) -> RecipeNote? {
//        <#code#>
//    }
//    
//    func toggleFavorite(recipeUUID: UUID) {
//        <#code#>
//    }
//    
//    
////    init(recipe: Recipe) {
//////        self.memoryStore = memoryStore
////        self.recipeId = recipe.id
////        memoryStore.loadRecipes(recipes: [recipe])
////    }
//    
//    func loadImage(sizeSmall: Bool) async {
//        return
//    }
//    ///
//    
//    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) {
//        //
//    }
//
//
//    
//    func deleteNotes(for recipeUUID: UUID) {
////        if var mem = memories[recipeUUID] {
////            mem.notes.removeAll()
////            memories[recipeUUID] = mem
////            save()
////        }
//    }
//    
//    func getImage(sizeSmall: Bool = true) async throws(FetchCacheError )-> Image? {
//        return Image("PlaceHolder")
//    }
//}

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
            // if unfavoriting, you might choose to drop notes
            // mem.notes.removeAll()
            memories[recipeUUID] = mem
        } else {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
    }
    
    
}
