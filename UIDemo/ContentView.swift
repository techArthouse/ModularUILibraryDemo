import SwiftUI
import ModularUILibrary

struct ContentView: View {
    @StateObject private var vm: RecipesViewModel
    @StateObject private var nav: AppNavigation = .shared
    @EnvironmentObject private var themeManager: ThemeManager
    
    init() {
        _vm = StateObject(wrappedValue: RecipesViewModel(
            cache: FetchCache.shared,
            memoryStore: RecipeDataSource.shared))
    }

    var body: some View {
        TabView {
            // 1) Home tab: recipe list + detail navigation
            NavigationStack(path: $nav.path) {
                RecipesView(vm: vm)
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let uuid):
                            if let item = vm.items.first(where: { $0.id == uuid }) {
                                RecipeDetailView(item: item, onToggleFavorite: {
                                    print("toggling")
                                    withAnimation {
                                        vm.toggleFavorite(recipeUUID: item.id)
                                    }
                                },
                                                 onSubmitNote: { note in
                                    vm.addNote(note, for: item.id)
                                })
                            }
                        default:
                            EmptyView()
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // 2) Favorites tab—placeholder for now
            Text("Favorites")
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }

            // 3) Profile tab
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .environmentObject(nav)
    }
}

@MainActor
final class AppNavigation: ObservableObject {
    static let shared = AppNavigation()
    
    @Published var path: [Route] = []
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
    }
}
#endif
