//
//  RecipeRowView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/16/25.
//


import SwiftUI
import ModularUILibrary

/// Takes up as much width and height as it can. specify size if you need different.
struct RecipeRowView: View {
    
        // Suppose the parent passed us a Binding<RecipeItem>:
        @ObservedObject var item: RecipeItem
        let onToggleFavorite: () -> Void
        let onSelectRow: () -> Void
        @EnvironmentObject private var nav: AppNavigation
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        
        var body: some View {
            
            FeatureItem(
                title: item.name,
                description: item.cuisine,
                isDisabled: item.recipe.isInvalid,
                config: .init(rounded: true, withBorder: false),
                action: {
                    print("action fire for item")
                    onSelectRow()
                },
                leading: {
                    ImageContainer(image: $item.image, size: dynamicTypeSize.photoDimension, accessibilityId: item.id.uuidString)
                        .equatable()
                        .border(.black.opacity(0.5), width: 1)
                        .onAppear{
                            print("i appear imagecontainer with image \(item.image != nil)")
                        }
                },
                trailing: {
                    ToggleIconButton(
                        iconOn: .system("star.fill"),
                        iconOff: .system("star"),
                        isDisabled: .constant(item.recipe.isInvalid),
                        isSelected: $item.isFavorite) {
                            onToggleFavorite()
                        }
                    .asStandardIconButtonStyle(withColor: .yellow)
                    .accessibilityLabel(Text("ToggleIconButton: \(item.id.uuidString)"))
                })
            .task {
                print("ran task")
                do {
                    guard let url = item.smallImageURL else {
                        throw URLError(.badURL)
                    }
                    guard item.image == nil else {
                        
                        print("not equal to nil")
                        return
                    }
                    item.image = try await FetchCache.shared.getImageFor(url: url)
                } catch let e as FetchCacheError {
                    switch e {
                    case .taskCancelled:
                        // We anticipate to fall here with a CancellationError as that is what's thrown when `task
                        // cancels a network call. but we wrap it in our own error.
                        // In our case we scrolled and the row running the request disappeared.
                        return
                    default:
                        // Any other error that would suggest we are still viewing the row but an error occured
                        print("Image load failed: \(e.localizedDescription)")
                        item.image = Image("imageNotFound")
                    }
                } catch let e {
                    // Any error we haven't anticipated
                    // (but it's not likely to happen since the methods define the throw type)
                    print("Error in row task. error: \(e.localizedDescription)")
                    item.image = Image("placeHolder")
                }
            }
            .onAppear {
                print("were appearing oh yeah")
                // By having this here we can always show a progressview whenever
                // we return to this item cell.
                item.image = nil
            }
        }
    }

#if DEBUG

struct RecipeRowView_Previews: PreviewProvider {
    static var previews: some View {
        let goodRecipe = Recipe.recipePreview(using: .good)!
        let invalidRecipe = Recipe.recipePreview(using: .malformed)!
        
        let goodItem = RecipeItem(recipe: goodRecipe)
        goodItem.image = Image(systemName: "photo") // Simulate image already loaded
        
        let badItem = RecipeItem(recipe: invalidRecipe)
        badItem.image = Image(systemName: "exclamationmark.triangle") // Placeholder for failed load
        
        let nav = AppNavigation.shared
        let themeManager = ThemeManager()
        
        return VStack {
            RecipeRowView(
                item: goodItem,
                onToggleFavorite: {
                    print("Favorite toggled for good item")
                },
                onSelectRow: {
                    print("Selected good item")
                }
            )
//            .background(.red)
//            .border(.blue, width: 2)
            .previewDisplayName("Good Recipe")
//            .padding()
//            .previewLayout(.sizeThatFits)
            .environmentObject(nav)
            .environmentObject(themeManager)
            
            RecipeRowView(
                item: badItem,
                onToggleFavorite: {
                    print("Favorite toggled for bad item")
                },
                onSelectRow: {
                    print("Selected bad item")
                }
            )
//            .frame(maxWidth: .infinity, maxHeight: 100)
            .background(.red)
            .previewDisplayName("Invalid Recipe")
//            .padding()
//            .previewLayout(.sizeThatFits)
            .environmentObject(nav)
            .environmentObject(themeManager)
//            .preferredColorScheme(.dark)
        }
    }
}
#endif
