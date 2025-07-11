import SwiftUI
import ModularUILibrary

struct ContentView: View {
    @StateObject private var vm: RecipesViewModel
    @StateObject private var vm2: RecipesViewModel
    
    @StateObject private var recipeStore: RecipeStore
    @StateObject private var nav: AppNavigation = .shared
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject var fetchCache: FetchCache
    
    
    init() {
        let store = RecipeStore(memoryStore: RecipeMemoryDataSource.shared, fetchCache: FetchCache()) // TODO: - fix this
        _recipeStore = StateObject(wrappedValue: store)
        _vm = StateObject(wrappedValue: RecipesViewModel(
            recipeStore: store,
            filterStrategy: AllRecipesFilter()))
        
        _vm2 = StateObject(wrappedValue: RecipesViewModel(
            recipeStore: store,
            filterStrategy: FavoriteRecipesFilter()))
    }

    var body: some View {
        TabView {
            // 1) Home tab: recipe list
            NavigationStack(path: $nav.path) {
                RecipesView(vm: vm)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
//                            if let item = vm.items.first(where: { $0.id == uuid }) {
                            RecipeDetailView(recipeRowVM: RecipeRowViewModel(recipeId: uuid, recipeStore: vm.recipeStore))
//                            }
                        default:
                            EmptyView()
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .onAppear {
                print("ok lets do it")
            }
            // 2) Favorites tab: list of favorites
            NavigationStack(path: $nav.path2) {
                FavoriteRecipesView(vm: vm)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
                            RecipeDetailView(recipeRowVM: RecipeRowViewModel(recipeId: uuid, recipeStore: vm.recipeStore))
                        default:
                            EmptyView()
                        }
                    }
            }
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
        ContentView()
            .environmentObject(themeManager)
            .environmentObject(FetchCache())
    }
}
#endif
