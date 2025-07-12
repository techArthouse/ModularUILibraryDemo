import SwiftUI
import ModularUILibrary

struct ContentView: View {
    // source of truth for recipes (it traces to a `recipeStore`
    
    @StateObject private var homeVM: RecipesViewModel
    @StateObject private var favoritesVM: RecipesViewModel
    @StateObject private var nav: AppNavigation = .shared
    @EnvironmentObject private var themeManager: ThemeManager
    
    
    
    
    init(recipeStore: RecipeStore) {
        _homeVM = StateObject(wrappedValue: RecipesViewModel(
            recipeStore: recipeStore,
            filterStrategy: AllRecipesFilter()))
        
            _favoritesVM = StateObject(wrappedValue: RecipesViewModel(
                recipeStore: recipeStore,
                filterStrategy: FavoriteRecipesFilter()))
    }

    var body: some View {
        TabView(selection: $nav.selectedTab) {
            // 1) Home tab: recipe list
            NavigationStack(path: $nav.path) {
                RecipesView(vm: homeVM)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
                            RecipeDetailView(recipeRowVM: RecipeRowViewModel(recipeId: uuid, recipeStore: homeVM.recipeStore))
                                .onAppear {
                                    print("recipedia 1")
                                }
                        default:
                            EmptyView()
                        }
                    }
            }
            .tag(Tab.home)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .onAppear {
                print("ok lets do it")
            }
            // 2) Favorites tab: list of favorites
            NavigationStack(path: $nav.path2) {
                FavoriteRecipesView(vm: favoritesVM)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
                            RecipeDetailView(recipeRowVM: RecipeRowViewModel(recipeId: uuid, recipeStore: favoritesVM.recipeStore))
                                .onAppear {
                                    print("recipedia 2")
                                }
                        default:
                            EmptyView()
                        }
                    }
            }
            .tag(Tab.favorites)
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
            
//            // 3) Profile tab
//            Text("Profile")
//                .tabItem {
//                    Label("Profile", systemImage: "person.crop.circle")
//                }
        }
        .environmentObject(nav)
    }
}

@MainActor
final class AppNavigation: ObservableObject {
    static let shared = AppNavigation()
    
    @Published var path: [Route] = []
    @Published var path2: [Route] = []
    @Published var selectedTab: Tab = .home
    
    private init() {
        
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let themeManager: ThemeManager = ThemeManager()
        
        ContentView(recipeStore: RecipeStore(memoryStore: RecipeMemoryDataSource.shared, fetchCache: FetchCache(path: "DevelopmentImageCache")))
            .environmentObject(themeManager)
    }
}
#endif
