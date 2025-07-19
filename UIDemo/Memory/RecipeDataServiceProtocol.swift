//
//  RecipeDataServiceProtocol.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/12/25.
//

import SwiftUI
import Combine

@MainActor
protocol RecipeDataServiceProtocol: ObservableObject {
    var allItems: [Recipe] { get }
    var memoryDataSource: any RecipeMemoryDataSourceProtocol { get }
    var imageCache: ImageCacheProtocol { get }
    var itemsPublisher: AnyPublisher<[Recipe], Never> { get }
    func setRecipes(recipes: [Recipe]) 
    
    // MARK: – Metadata
    func title(for id: UUID) -> String // title for recipe
    func description(for id: UUID) -> String // cuisine
    func isNotValid(for id: UUID) -> Bool // whether decoded model meets requirments
    // (i.e. has title, description, and id)
    
    // MARK: – Favorites
    func isFavorite(for id: UUID) -> Bool
    func toggleFavorite(_ id: UUID)
    func setFavorite(_ favorite: Bool, for id: UUID)
    
    // MARK: – Notes
    func notes(for id: UUID) -> [RecipeNote]
    func addNote(_ text: String, for id: UUID)
    func deleteNotes(for id: UUID)
    
    // MARK: – URLs
    func smallImageURL(for id: UUID) -> URL?
    func largeImageURL(for id: UUID) -> URL?
    func sourceWebsiteURL(for id: UUID) -> URL?
    func youtubeVideoURL(for id: UUID) -> URL?
    
    // MARK: – Image Cache operation
    func refreshImageCache() async // we only need to be able to refresh imageCache
}
