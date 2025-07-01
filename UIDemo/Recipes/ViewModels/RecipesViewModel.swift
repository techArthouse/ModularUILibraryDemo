//
//  RecipesViewModel.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI
import Combine

@MainActor
class RecipesViewModel: ObservableObject {
    @Published var items: [RecipeItem] = []
    @Published var searchQuery: String = ""
    @Published var selectedCuisine: String?
    @Published var searchModel: SearchViewModel?

    @ObservedObject var recipeStore: RecipeStore
//    private let memoryStore: RecipeMemoryStoreProtocol
    private let filterStrategy: RecipeFilterStrategy
    private var cancellables = Set<AnyCancellable>()
    let filterTrigger = PassthroughSubject<Void, Never>()
    
    let recipesLoadedTrigger = PassthroughSubject<Void, Never>()
    
    // MARK: - Init
    
    init(recipeStore: RecipeStore, filterStrategy: RecipeFilterStrategy) {
//        self.memoryStore = memoryStore
        self.recipeStore = recipeStore
        self.filterStrategy = filterStrategy
        
        recipesLoadedTrigger
            .flatMap { _ in
                    recipeStore.itemsPublisher
                
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] newItems in
                
                self?.items = newItems.map({ recipe in
                    var recipeItem = RecipeItem(recipe)
                    recipeItem.isFavorite = recipeStore.isFavorite(for: recipe.id)
                    recipeItem.notes = recipeStore.notes(for: recipe.id)
                    return recipeItem
                }).filter({
                    if filterStrategy.isFavorite {
                        $0.isFavorite
                    } else {
                        true
                    }
                })
            }
            .store(in: &cancellables)
        
        filterTrigger
            .flatMap { _ in
                return Publishers.CombineLatest3(
                    recipeStore.itemsPublisher,
                    self.$selectedCuisine.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
                    self.$searchQuery.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                )
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] items, cuisine, query in
                guard let strongSelf = self else { return }
                let filteredIds = strongSelf.filter(items, cuisine: cuisine, query: query)
//                for (i, item) in strongSelf.items.enumerated() {
//                  let shouldShow = filteredIds.contains(item.id)
//                  // each row waits i * 50ms before animating
////                  DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
//                    withAnimation(.easeInOut(duration: 0.3 + (Double(i) * 0.45))) {
//                      item.selected = shouldShow
//                    }
////                  }
//                }
                
                for item in strongSelf.items {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        item.selected = filteredIds.contains(item.id)
                    }
                }
            }
            .store(in: &cancellables)
        
//        filterTrigger
//            .flatMap { _ in
//                print("filtertriggered")
//                return Publishers.CombineLatest3(
//                    recipeStore.itemsPublisher,
//                    self.$selectedCuisine.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
//                    self.$searchQuery.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
//                )
//            }
//            .map { items, cuisine, query in
//                let filteredIds = filterStrategy.filter(items, cuisine: cuisine, query: query)
//                for item in self.items {
//                    if filteredIds.contains(item.id) {
//                        item.selected = true
//                    } else {
//                        item.selected = false
//                    }
//                }
//                
//            }
////            .map { items, cuisine, query in
////                filterStrategy.filter(items, cuisine: cuisine, query: query)
////            }
//            .receive(on: RunLoop.main)
//            .sink { [weak self] newItems in
//                self?.filteredIDs = newItems.map(\.id)
//            }
//            .store(in: &cancellables)

    }
    
    /// testing and taken from filterstrategy
    func filter(_ items: [Recipe], cuisine: String?, query: String?) -> [UUID] {
        var filtered = items
        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if let query = query, !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered.map({$0.id})
    }
    
    // MARK: - Public API
    
    /// Start FetchCache using pathComponent.
    /// Succeeds unless any error occurs in the cache initialization procees. throws a verbose error if fails.
    /// the error
    func startCache(path: String) throws {
        print("Starting cache at path: \(path)")
        try recipeStore.startCache(path: path) // FetchCache.shared.openCacheDirectoryWithPath(path: path)
    }
    
    /// resets fields to reload again
    func reload() async throws -> Bool {
        self.items.removeAll()
        try? await Task.sleep(for: .seconds(0.5)) // for visual feedback on reload
        
        self.searchQuery = ""
        self.selectedCuisine = nil
        self.searchModel = nil
        
        await FetchCache.shared.refresh()
        return try await loadRecipes()
    }
    
//    func addNote(_ text: String, for recipeUUID: UUID) {
//        guard memoryStore.isFavorite(for: recipeUUID) else { return }
//        if let note = memoryStore.addNote(text, for: recipeUUID) {
//            recipeStore.addNote(note, for: recipeUUID)
//        }
//    }
    
    var cusineCategories: [String] {
        var categories = Set<String>()
        let itemIds = self.items.map { $0.id }
        for item in recipeStore.allItems.filter({ itemIds.contains($0.id) }) {
            categories.insert(item.cuisine)
        }
        return Array(categories)
    }
}

struct SearchViewModel: Identifiable {
    var id: String { text }
    var text: String
    var categories: [String] = []
}


@MainActor
protocol RecipeDataConsumer {
    var items: [RecipeItem] { get }
    var recipeStore: RecipeStore { get }
//    func toggleFavorite(recipeUUID: UUID)
    func loadRecipes(from url: URL?) async throws -> Bool
}

extension RecipesViewModel: RecipeDataConsumer {
    
    
#if DEBUG
    
    /// Load recipes and update listeners through `RecipeStore`
    /// Returns true if parsing succeeded, false otherwise.
    func loadRecipes(from url: URL? = nil) async throws -> Bool {
        do {
            let recipes = try await Recipe.allFromJSON(using: .good) // Network call
            recipeStore.loadRecipes(recipes: recipes)
//            filterSend()
            recipesLoadedTrigger.send()
            return !recipes.isEmpty
        } catch let e as RecipeDecodeError {
            throw e
        }
    }
    
#else
    
    /// Load and wrap your recipes in order
    func loadRecipes(from url: URL? = nil) {
        //        FetchCache.shared.load()
        //        let recipes =
        print("Asdfasdfsdf")
        let recipes = Recipe.allFromJSON(using: .good) // Network call
        self.items.append(contentsOf: recipes.map ({ recipe in
            RecipeItem(recipe: recipe)
        }))
        //        self.items = recipes.map ({ recipe in
        //            RecipeItem(recipe: recipe)
        //        })
        print("Asdfasdfsdf...return")
        return
    }
    
#endif
    
    
//    func toggleFavorite(recipeUUID: UUID) {
//        print("is favorite beggining: \(memoryStore.isFavorite(for: recipeUUID))")
//        memoryStore.toggleFavorite(recipeUUID: recipeUUID)
//        recipeStore.toggleFavorite(recipeUUID)
//        if !memoryStore.isFavorite(for: recipeUUID) {
//            print("it's not favorite")
//            memoryStore.deleteNotes(for: recipeUUID)
//            recipeStore.deleteNotes(for: recipeUUID)
//        }
//    }
}

extension RecipesViewModel: Filterable {
    func filterSend() {
        filterTrigger.send()
    }
}

@MainActor
protocol RecipeFilterStrategy {
    func filter(_ items: [Recipe], cuisine: String?, query: String?) -> [UUID]
}

extension RecipeFilterStrategy {
    var isFavorite: Bool {
        (self as? FavoriteRecipesFilter) != nil
    }
}

struct AllRecipesFilter: RecipeFilterStrategy {
    
    func filter(_ items: [Recipe], cuisine: String?, query: String?) -> [UUID] {
        var filtered = items
        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if let query = query, !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered.map({$0.id})
    }
}


struct FavoriteRecipesFilter: RecipeFilterStrategy {
    func filter(_ items: [Recipe], cuisine: String?, query: String?) -> [UUID] {
        var filtered = items // .filter({ $0.isFavorite })
        if let cuisine = cuisine {
            filtered = filtered.filter { $0.cuisine.lowercased() == cuisine.lowercased() }
        }
        if let query = query, !query.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered.map({$0.id})
    }
}
    
@MainActor
protocol Filterable {
    func filterSend()
}

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
  func getImage(for id: UUID, smallImage: Bool) async throws(FetchCacheError) -> Image?
    func startCache(path: String) throws(FetchCacheError)
}

//extension RecipeStore: RecipeService {
//    func title(for id: UUID) -> String {
//        guard let title = allItems.first(where: { $0.id == id })?.name else { return "" }
//        return title
//    }
//    func description(for id: UUID) -> String {
//        guard let title = allItems.first(where: { $0.id == id })?.cuisine else { return "" }
//        return title
//    }
//    
//    func isNotValid(for id: UUID) -> Bool {
//        guard let isInvalid = allItems.first(where: { $0.id == id })?.isNotValid else { return false }
//        return isInvalid
//    }
//  func isFavorite(for id: UUID) -> Bool          { memoryStore.isFavorite(for: id) }
//    func toggleFavorite(_ id: UUID)                { memoryStore.toggleFavorite(recipeUUID: id) }
//    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) { memoryStore.setFavorite(favorite, for: recipeUUID) }
//  func notes(for id: UUID) -> [RecipeNote]       { memoryStore.notes(for: id) }
//  func addNote(_ text: String, for id: UUID)     { memoryStore.addNote(text, for: id) }
//    func deleteNotes(for id: UUID) {
//        memoryStore.deleteNotes(for: id)
//    }
//    func smallImageURL(for id: UUID) -> URL? {
//        guard let url = allItems.first(where: { $0.id == id })?.smallImageURL else { return nil }
//        return url
//    }
//    func largeImageURL(for recipeId: UUID) -> URL? {
//        guard let url = allItems.first(where: { $0.id == recipeId })?.largeImageURL else { return nil }
//        return url
//    }
//    
//    func sourceWebsiteURL(for recipeId: UUID) -> URL? {
//        guard let url = allItems.first(where: { $0.id == recipeId })?.sourceWebsiteURL else { return nil }
//        return url
//    }
//    
//    func youtubeVideoURL(for recipeId: UUID) -> URL? {
//        guard let url = allItems.first(where: { $0.id == recipeId })?.youtubeVideoURL else { return nil }
//        return url
//    }
//    func getImage(for recipeId: UUID, smallImage: Bool = true) async throws(FetchCacheError) -> Image? {
//        if smallImage {
//            guard let url = allItems.first(where: { $0.id == recipeId })?.smallImageURL else {
//                print("error geting url from recipe model")
//                return nil
//            }
//            return try await FetchCache.shared.getImageFor(url: url)
//        } else {
//            guard let url = allItems.first(where: { $0.id == recipeId })?.largeImageURL else {
//                print("error geting url from recipe model")
//                return nil
//            }
//            return try await FetchCache.shared.getImageFor(url: url)
//        }
//    }
//}

@MainActor
class RecipeStore: ObservableObject, RecipeService {
    @Published private(set) var allItems: [Recipe] = []
    var memoryStore: RecipeMemoryStoreProtocol // should i use protocol for testing?
    @Published private var fetchCache: ImageCache
    
    init(memoryStore: RecipeMemoryStoreProtocol, fetchCache: ImageCache) {
        self.memoryStore = memoryStore
        self.fetchCache = fetchCache
    }
    var itemsPublisher: AnyPublisher<[Recipe], Never> {
        $allItems.eraseToAnyPublisher()
    }

//    func toggleFavorite(_ id: UUID) {
//        let toggledFavoriteValue = !self.isFavorite(for: id) // NOT(`!`) toggles current value.
//        memoryStore.setFavorite(toggledFavoriteValue, for: id)
//    }

    func loadRecipes(recipes: [Recipe]) {
        print("we loaded recipe with id: \(recipes.first!.id)")
        allItems = recipes
    }
    
    // MARK: - Recipe Acessors
    func title(for id: UUID) -> String {
        guard let title = allItems.first(where: { $0.id == id })?.name else { return "" }
        return title
    }
    func description(for id: UUID) -> String {
        guard let title = allItems.first(where: { $0.id == id })?.cuisine else { return "" }
        return title
    }
    
    func isNotValid(for id: UUID) -> Bool {
        guard let isInvalid = allItems.first(where: { $0.id == id })?.isNotValid else { return false }
        return isInvalid
    }
  func isFavorite(for id: UUID) -> Bool          { memoryStore.isFavorite(for: id) }
    func toggleFavorite(_ id: UUID)                { memoryStore.toggleFavorite(recipeUUID: id) }
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) { memoryStore.setFavorite(favorite, for: recipeUUID) }
  func notes(for id: UUID) -> [RecipeNote]       { memoryStore.notes(for: id) }
  func addNote(_ text: String, for id: UUID)     { memoryStore.addNote(text, for: id) }
    func deleteNotes(for id: UUID) {
        memoryStore.deleteNotes(for: id)
    }
    func smallImageURL(for id: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == id })?.smallImageURL else { return nil }
        return url
    }
    func largeImageURL(for recipeId: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == recipeId })?.largeImageURL else { return nil }
        return url
    }
    
    func sourceWebsiteURL(for recipeId: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == recipeId })?.sourceWebsiteURL else { return nil }
        return url
    }
    
    func youtubeVideoURL(for recipeId: UUID) -> URL? {
        guard let url = allItems.first(where: { $0.id == recipeId })?.youtubeVideoURL else { return nil }
        return url
    }
    func getImage(for recipeId: UUID, smallImage: Bool = true) async throws(FetchCacheError) -> Image? {
        if smallImage {
            guard let url = allItems.first(where: { $0.id == recipeId })?.smallImageURL else {
                print("error geting url from recipe model")
                return nil
            }
            return try await fetchCache.getImageFor(url: url)
        } else {
            guard let url = allItems.first(where: { $0.id == recipeId })?.largeImageURL else {
                print("error geting url from recipe model")
                return nil
            }
            return try await fetchCache.getImageFor(url: url)
        }
    }
    func startCache(path: String) throws(FetchCacheError) {
        try fetchCache.openCacheDirectoryWithPath(path: path)
    }
}
