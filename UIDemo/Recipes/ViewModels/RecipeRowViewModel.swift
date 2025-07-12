//
//  RecipeRowViewModel.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/29/25.
//

import SwiftUI
import Combine

@MainActor
final class RecipeRowViewModel: ObservableObject {
    private let imageLoader: ImageLoader
    var recipeId: UUID
//    @ObservedObject private var vm: RecipesViewModel
    @ObservedObject var recipeStore: RecipeStore
    @Published private(set) var image: Image?
    @Published var isFavorite: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(recipeId: UUID, recipeStore: RecipeStore) {
        print("omgomg2")
        self.recipeId = recipeId
        self.recipeStore = recipeStore
        isFavorite = recipeStore.isFavorite(for: recipeId)
        self.imageLoader = ImageLoader(url: recipeStore.smallImageURL(for: recipeId), cache: recipeStore.fetchCache)
    }
    
    /// Binding: ViewModel.image ← ImageLoader.image
    private func bindImageLoader() {
        imageLoader.$image
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { print("Combine: Received image from loader: \($0 != nil)") })
            .assign(to: \.image, on: self)
            .store(in: &cancellables)
    }
    
    func load() async {
        bindImageLoader()
        await self.imageLoader.load()
//        isFavoriteBinding = recipeStore.isFavorite(for: recipeId)
    }
    
    var isDisabledBinding: Binding<Bool> {
        Binding(get: {
//            print("wait why are we here")
            return self.isNotValid
        }, set: { _ in
        })
    }
    
    var accessibilityId: String {
        recipeId.uuidString
    }
    
    var isFavoriteBinding: Binding<Bool> {
      Binding(
        get: { [weak self] in
            guard let self = self else { return false }
            print( "get favorite for id \(self.recipeId) is \(isFavorite)")
            return isRecipFavorited },
        set: { [weak self] newValue in
            guard let self = self else { return }
            print("set favorite \(newValue) for id \(self.recipeId)")
            self.objectWillChange.send()
            self.recipeStore.setFavorite(newValue, for: self.recipeId)
//            isFavorite = newValue
        }
      )
    }

}

extension RecipeRowViewModel: RecipeRowObjectProtocol, RecipeSourcesProtocol, RecipeMemoryItemProtocol {
//    func loadImage(sizeSmall: Bool) async {
////        Task {
//            do {
//                self.imageLoader.image = try await getImage(sizeSmall: sizeSmall) ?? Image("placeHolder")
//            } catch let e as FetchCacheError {
//                switch e {
//                case .taskCancelled:
//                    print("task cancelled?")
//                    // We anticipate to fall here with a CancellationError as that is what's thrown when `task
//                    // cancels a network call. but we wrap it in our own error.
//                    // In our case we scrolled and the row running the request disappeared.
//                    return
//                default:
//                    // Any other error that would suggest we are still viewing the row but an error occured
//                    print("Image load failed: \(e.localizedDescription)")
//                    self.imageLoader.image = Image("imageNotFound")
//                }
//            }
////        }
//    }
}

@MainActor
protocol RecipeRowObjectProtocol {
    var recipeStore: RecipeStore { get }
    var recipeId: UUID { get }
//    func loadImage(sizeSmall: Bool) async // Use this to call getImage and request from the network/cache, then what to fallback to in case of FetchCacheError. `see getImage()`
}

extension RecipeRowObjectProtocol {
    var title: String {
        recipeStore.title(for: recipeId)
    }
    
    var description: String {
        recipeStore.description(for: recipeId)
    }
    
    var isNotValid: Bool {
        recipeStore.isNotValid(for: recipeId)
    }
    
    func getImage(sizeSmall: Bool = true) async throws(FetchCacheError )-> Image? {
        return nil // try await recipeStore.getImage(for: recipeId, smallImage: sizeSmall)
    }
}


@MainActor
protocol RecipeSourcesProtocol {
    var recipeStore: RecipeStore { get }
    var recipeId: UUID { get }
}

extension RecipeSourcesProtocol {
    var sourceURL: URL? {
        recipeStore.sourceWebsiteURL(for: recipeId)
    }
    
    var videoURL: URL? {
        recipeStore.youtubeVideoURL(for: recipeId)
    }
}

@MainActor
protocol RecipeMemoryItemProtocol: AnyObject {
    var recipeStore: RecipeStore { get }
    var recipeId: UUID { get }
//    var isFavoriteBinding: Binding<Bool> { get set }
}

extension RecipeMemoryItemProtocol {
    var notes: [RecipeNote] {
        recipeStore.notes(for: recipeId)
    }
    
    func addNote(_ text: String) {
        recipeStore.addNote(text, for: recipeId)
    }
    
    var isRecipFavorited: Bool {
        recipeStore.isFavorite(for: recipeId)
    }
    
    func setFavorite(_ favorite: Bool) {
        recipeStore.setFavorite(favorite, for: recipeId)
//        isFavoriteBinding = favorite
//        isFavoriteBinding.wrappedValue = favorite
    }
    
    func toggleFavorite() {
        recipeStore.toggleFavorite(recipeId)
//        isFavoriteBinding.toggle()
    }
}
