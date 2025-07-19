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
    @Published var recipeStore: any RecipeDataServiceProtocol
    @Published private(set) var image: Image?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(recipeId: UUID, recipeStore: any RecipeDataServiceProtocol) {
        self.recipeId = recipeId
        self.imageLoader = ImageLoader(url: recipeStore.smallImageURL(for: recipeId), cache: recipeStore.imageCache)
        self.recipeStore = recipeStore
    }
    
    /// Binding: ViewModel.image ← ImageLoader.image
    private func bindImageLoader() {
        imageLoader.$image
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { Logger.log("Combine: Received image from loader: \($0 != nil)") })
            .assign(to: \.image, on: self)
            .store(in: &cancellables)
    }
    
    func load() async {
        bindImageLoader()
        await self.imageLoader.load()
    }
    
    var isDisabledBinding: Binding<Bool> {
        Binding(get: {
            return !self.isValid
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
                return recipeStore.isFavorite(for: recipeId) },
            set: { [weak self] newValue in
                guard let self = self else { return }
                objectWillChange.send()
                self.recipeStore.setFavorite(newValue, for: self.recipeId)
            }
        )
    }
}

extension RecipeRowViewModel {
    var title: String {
        recipeStore.title(for: recipeId)
    }
    
    var description: String {
        recipeStore.description(for: recipeId)
    }
    
    var isValid: Bool {
        recipeStore.isRecipeValid(for: recipeId)
    }
    
    var sourceURL: URL? {
        recipeStore.sourceWebsiteURL(for: recipeId)
    }
    
    var videoURL: URL? {
        recipeStore.youtubeVideoURL(for: recipeId)
    }
    
    var notes: [RecipeNote] {
        recipeStore.notes(for: recipeId)
    }
    
    func addNote(_ text: String) {
        recipeStore.addNote(text, for: recipeId)
    }
    
    var isFavorite: Bool {
        recipeStore.isFavorite(for: recipeId)
    }
    
    func setFavorite(_ favorite: Bool) {
        recipeStore.setFavorite(favorite, for: recipeId)
    }
    
    func toggleFavorite() {
        recipeStore.toggleFavorite(recipeId)
    }
}
