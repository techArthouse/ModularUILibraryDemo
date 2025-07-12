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
    enum LoadPhase {
        case idle
        case loading
        case success
        case failure(String)
    }

    @Published var items: [RecipeItem] = []
    @Published var loadPhase: LoadPhase = .idle
    
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
        self.recipeStore = recipeStore
        self.filterStrategy = filterStrategy
        
        loadSubscriptions()
    }
    
    /// The 1st subscription keeps items synced with recipes source of truth.
    /// the 2nd listens to filter options and mutates items in place to determine if item should be showed.
    /// By modifying in place we preserve swiftui's internal identity property and keeps animations intact.
    private func loadSubscriptions() {
        // 1.
        recipeStore
            .itemsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] recipes in
                guard let self = self else { return }
                // create one RecipeItem per recipe. no filter
                self.items = recipes.map { recipe in
                    let item = RecipeItem(recipe)
//                    item.isFavorite = self.recipeStore.isFavorite(for: recipe.id)
//                    item.notes = self.recipeStore.notes(for: recipe.id)
                    return item
                }
                self.applyFilter(animated: false)
            }
            .store(in: &cancellables)
        
        // 2.
        Publishers
            .CombineLatest(
                $selectedCuisine,
                $searchQuery // .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.applyFilter(animated: true)
            }
            .store(in: &cancellables)
    }
    
    private func applyFilter(animated: Bool) {
        // computes which recipe ids should be visible
        let visibleIDs = self.filterStrategy.filter(recipeStore.allItems,
                                                    cuisine: selectedCuisine,
                                                    query: searchQuery).filter({ id in
            if self.filterStrategy.isFavorite {
                return self.recipeStore.isFavorite(for: id)
            } else {
                return true
            }
        })
        
        // update each item's `selected` in place to preserve animations and prevent odd ui flickers
        for (idx, item) in items.enumerated() {
            let shouldShow = visibleIDs.contains(item.id)
            
            if animated {
                // stagger them by index for a “fan-out” effect (TODO: - animation not reflecting fan out)
                let delay = Double(idx) * 0.03
                withAnimation(.easeInOut.delay(delay)) {
                    items[idx].selected = shouldShow
                }
            } else {
                items[idx].selected = shouldShow
            }
        }
    }
    
    // MARK: - Public API
    
    /// Called on first appearance. Start the cache and load recipes.
    func loadAll() {
        loadPhase = .loading

        Task {
            do {
                try await self.loadRecipes()
                loadPhase = .success
            }
            catch {
                loadPhase = .failure(error.localizedDescription)
            }
        }
    }
    
    func reloadAll() async {
        loadPhase = .loading
        
        do {
            try await Task.sleep(for: .seconds(0.5)) // for UX feedback
            await recipeStore.refresh()                 // clear imagecache
            try await self.loadRecipes()
            self.searchQuery = ""
            self.selectedCuisine = nil
            self.searchModel = nil
            loadPhase = .success
        }
        catch {
            loadPhase = .failure(error.localizedDescription)
        }
    }
    
    var cusineCategories: [String] {
        var categories = Set<String>()
        let itemIds = self.items.filter({ item in
            item.selected
        }).map { $0.id }
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
    func loadRecipes(from url: URL?) async throws
}

extension RecipesViewModel: RecipeDataConsumer {
    
    
#if DEBUG
    
    /// Load recipes and update listeners through `RecipeStore`
    /// Returns true if network succeeded, false otherwise.
    internal func loadRecipes(from url: URL? = nil) async throws {
        let recipes = try await Recipe.allFromJSON(using: .malformed)
        recipeStore.loadRecipes(recipes: recipes)
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

