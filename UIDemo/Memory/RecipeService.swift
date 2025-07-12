//
//  RecipeService.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/12/25.
//

import SwiftUI
import Combine

@MainActor
protocol RecipeService: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
    
    // MARK: – Metadata
    func title(for id: UUID) -> String
    func description(for id: UUID) -> String
    func isNotValid(for id: UUID) -> Bool
    
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
    
    // MARK: – Image Loading
    /// Fetches the small or large image for the given recipe.
    //  func getImage(for id: UUID, smallImage: Bool) async throws(FetchCacheError) -> Image?
//    func startCache(path: String) throws(FetchCacheError)
    func refresh() async
}
