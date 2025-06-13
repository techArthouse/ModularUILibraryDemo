import SwiftUI
import ModularUILibrary

struct ContentView: View {
    @StateObject private var vm = RecipesViewModel()
    @StateObject private var nav: AppNavigation = .shared
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView {
            // 1) Home tab: recipe list + detail navigation
            NavigationStack(path: $nav.path) {
                RecipesView(vm: vm)
                    .navigationTitle("Recipes")
                    .navigationDestination(for: Route.self) { recipe in
                        switch recipe {
                        case .recipeDetail(let recipe):
                            
                            RecipeDetailView(recipe: recipe)
                                .onAppear {
                                    print(recipe)
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

//struct ContentView: View {
//    @StateObject private var nav: AppNavigation = .shared
//    @StateObject private var vm: RecipesViewModel = RecipesViewModel()
//    @EnvironmentObject var themeManager: ThemeManager
//
//    var body: some View {
//        NavigationStack(path: $nav.path) {
//            VStack {
//                if nav.path.isEmpty {
//                    LandingView()
//                } else {
//                    TabView(selection: $nav.selectedTab) {
//                        RecipesView(vm: vm)
////                            .environmentObject(themeManager)
//                            .tag(Tab.home)
//
//                        Text("Favorites")
//                            .tag(Tab.favorites)
//
//                        Text("Profile")
//                            .tag(Tab.profile)
//                    }
//                    .onChange(of: nav.selectedTab) { new in
//                        if new == .home && nav.selectedTab == new {
//                            // reset scroll to top if already on home
//                            ScrollViewProxy.shared.scrollToTop()
//                        }
//                    }
//                }
//            }
//            .environmentObject(nav)
//            .navigationDestination(for: Route.self) { route in
//                switch route {
//                case .recipes:
//                    RecipesView(vm: vm)
//                case .recipeDetail(let recipe):
//                    RecipeDetailView(recipe: recipe)
//                default:
//                    EmptyView()
//                }
//            }
//        }
//    }
//}

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
