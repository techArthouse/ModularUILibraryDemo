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
    @Published var image: Image?
    var placeholderImage: Image
    var recipeId: UUID
//    @ObservedObject private var vm: RecipesViewModel
    @ObservedObject var recipeStore: RecipeStore
    @Published var isFavoriteBinding: Bool
    
    private var cancellables = Set<AnyCancellable>()
    
    init(placeholder: Image? = nil, recipeId: UUID, recipeStore: RecipeStore, vm: RecipesViewModel? = nil) {
        self.placeholderImage = placeholder ?? Image("placeHolder")
        self.image = self.placeholderImage
        self.recipeId = recipeId
        self.recipeStore = recipeStore
//        self.vm = vm
        isFavoriteBinding = recipeStore.isFavorite(for: recipeId)
        
    }
    
    func onAppear() {
        
//        isFavoriteBinding = recipeStore.isFavorite(for: recipeId)
    }
//    var isFavoriteBinding: Binding<Bool> {
//        Binding<Bool>(
//          get:  { self.recipeStore.isFavorite(for: self.recipeId) },
//          set: { _ in self.recipeStore.toggleFavorite(self.recipeId) }
//        )
//      }
    
//    var isFavoriteBinding: Binding<Bool> {
//        Binding(get: {
//            print("getting")
//            return self.isRecipFavorited
//                    
//            
//        }, set: { newValue in
//            print("is it setting? \(newValue)")
//            
//            self.objectWillChange.send()
//            self.setFavorite(newValue)
////            self.setFavorite(value)
//        })
//    }
    
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
    // …
}

extension RecipeRowViewModel: RecipeRowObjectProtocol, RecipeSourcesProtocol, RecipeMemoryItemProtocol {
    func loadImage(sizeSmall: Bool) async {
//        Task {
            do {
                self.image = try await getImage(sizeSmall: sizeSmall) ?? placeholderImage
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
                    image = Image("imageNotFound")
                }
            }
//        }
    }
}

@MainActor
protocol RecipeRowObjectProtocol {
    var recipeStore: RecipeStore { get }
    var recipeId: UUID { get }
    func loadImage(sizeSmall: Bool) async // Use this to call getImage and request from the network/cache, then what to fallback to in case of FetchCacheError. `see getImage()`
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
        return try await recipeStore.getImage(for: recipeId, smallImage: sizeSmall)
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
    var isFavoriteBinding: Bool { get set }
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
        isFavoriteBinding.toggle()
    }
}


@MainActor
final class FavoriteFecipeRowViewModel: ObservableObject {
    @Published var image: Image?
    var placeholderImage: Image
    var recipeId: UUID
    var recipeStore: RecipeStore
    @Published var isFavoriteBinding: Bool
    
    init(placeholder: Image? = nil, recipeId: UUID, memoryStore: RecipeStore) {
        self.placeholderImage = placeholder ?? Image("placeHolder")
        self.image = self.placeholderImage
        self.recipeId = recipeId
        self.recipeStore = memoryStore
        isFavoriteBinding = memoryStore.isFavorite(for: recipeId)
    }
    
//    var isFavoriteBinding: Binding<Bool> {
//        Binding(get: {
//            self.isRecipFavorited
//        }, set: { value in
//            self.setFavorite(value)
//        })
//    }
    
    var isDisabledBinding: Binding<Bool> {
        Binding(get: {
            self.isNotValid
        }, set: { _ in
        })
    }
    
    
    // …
}

extension FavoriteFecipeRowViewModel: RecipeRowObjectProtocol, RecipeSourcesProtocol, RecipeMemoryItemProtocol {
    func loadImage(sizeSmall: Bool) async {
//        Task {
            do {
                self.image = try await getImage(sizeSmall: sizeSmall) ?? placeholderImage
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
                    image = Image("imageNotFound")
                }
            }
//        }
    }
}
