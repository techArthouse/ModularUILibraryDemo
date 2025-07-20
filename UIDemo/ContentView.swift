import SwiftUI
import ModularUILibrary

/// The root content view, displaying a tabbed interface for Home and Favorites.
/// It sets up two view models with appropriate filter strategies, and shares
/// a navigation object to handle deep links and programmatic navigation.
struct ContentView: View {
    /// ViewModel for displaying all recipes.
    @StateObject private var homeVM: RecipesViewModel
    /// ViewModel for displaying favorite recipes.
    @StateObject private var favoritesVM: RecipesViewModel
    /// ViewModel for displaying favorite recipes.
    @StateObject private var discoverVM: DiscoverViewModel
    /// Shared navigation controller for tab-based navigation.
    @StateObject private var nav: AppNavigation = .shared
    /// Injected theme manager for styling.
    @EnvironmentObject private var themeManager: ThemeManager
    
//    @ObservedObject var recipeStore: RecipeDataService
    
//    /// Constructs ContentView with the given RecipeStore,
//    /// creating a view model for all recipes and another for favorites.
//    /// - Parameter recipeStore: The central store managing recipe data.
//    init(makeHomeVM: @escaping () -> RecipesViewModel, makeFavoritesVM: @escaping () -> RecipesViewModel) {
//        _homeVM = StateObject(wrappedValue: makeHomeVM())
//        _favoritesVM = StateObject(wrappedValue: makeFavoritesVM())
//    }

//    /// Constructs ContentView with the given RecipeStore,
//    /// creating a view model for all recipes and another for favorites.
//    /// - Parameter recipeStore: The central store managing recipe data.
//    init(makeHomeVM: RecipesViewModel, makeFavoritesVM: RecipesViewModel) {
//        _homeVM = StateObject(wrappedValue: makeHomeVM)
//        _favoritesVM = StateObject(wrappedValue: makeFavoritesVM)
//    }
    
    /// creating a view model for all recipes and another for favorites.
    /// - Parameter recipeStore: The central store managing recipe data.
    init(makeHomeVM: RecipesViewModel, makeFavoritesVM: RecipesViewModel, discoverVM: DiscoverViewModel) {
        _homeVM = StateObject(wrappedValue: makeHomeVM)
        _favoritesVM = StateObject(wrappedValue: makeFavoritesVM)
        _discoverVM = StateObject(wrappedValue: discoverVM)
    }
    
    var body: some View {
        TabView(selection: $nav.selectedTab) {
            // Home tab
            NavigationStack(path: $nav.homePath) {
                RecipesView(vm: homeVM)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
                            RecipeDetailView(
                                recipeRowVM: RecipeRowViewModel(
                                    recipeId: uuid,
                                    recipeStore: homeVM.recipeStore))
                        default:
                            EmptyView()
                        }
                    }
            }
            .tag(Tab.home)
            .tabItem { Label("Home", systemImage: "house.fill") }
            
            // Favorites tab
            NavigationStack(path: $nav.favoritesPath) {
                FavoriteRecipesView(vm: favoritesVM)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
                            RecipeDetailView(
                                recipeRowVM: RecipeRowViewModel(
                                    recipeId: uuid,
                                    recipeStore: favoritesVM.recipeStore))
                        default:
                            EmptyView()
                        }
                    }
                    .background(.gray.opacity(0.09))
            }
            .tag(Tab.favorites)
            .tabItem { Label("Favorites", systemImage: "star.fill") }
            
            // Discover tab
            NavigationStack(path: $nav.discoverPath) {
                DiscoverView(vm: discoverVM)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
                            RecipeDetailView(
                                recipeRowVM: RecipeRowViewModel(
                                    recipeId: uuid,
                                    recipeStore: discoverVM.recipeStore))
                        default:
                            EmptyView()
                        }
                    }
                    .background(.gray.opacity(0.09))
            }
            .tag(Tab.discover)
            .tabItem { Label("Discover", systemImage: "rectangle.and.text.magnifyingglass") }
        }
        .environmentObject(nav)
    }
}

/// Manages tab and path navigation for the app.
@MainActor
final class AppNavigation: ObservableObject {
    /// Shared singleton instance.
    static let shared = AppNavigation()
    /// Navigation path for the Home tab.
    @Published var homePath: [Route] = []
    /// Navigation path for the Favorites tab.
    @Published var favoritesPath: [Route] = []
    /// Navigation path for the Discover tab.
    @Published var discoverPath: [Route] = []
    /// Currently selected tab.
    @Published var selectedTab: Tab = .home
    private init() {}
}

// MARK: - DEBUG Structures/Previews

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let memoryStore = RecipeMemoryDataSource()
        let networkService = NetworkService()
        let recipeStore = RecipeDataService(
            memoryStore: memoryStore,
            fetchCache: CustomAsyncImageCache(path: "PreviewCache", networkService: networkService)
        )
        let themeManager: ThemeManager = ThemeManager()

        ContentView(
            makeHomeVM:
                RecipesViewModel(recipeStore: recipeStore,
                                 filterStrategy: AllRecipesFilter(),
                                 networkService: networkService)
            , makeFavoritesVM:
                RecipesViewModel(recipeStore: recipeStore,
                                 filterStrategy: FavoriteRecipesFilter(),
                                 networkService: networkService)
            , discoverVM: DiscoverViewModel(recipeStore: recipeStore)
            
        )
        .environmentObject(themeManager)
    }
}

#endif
