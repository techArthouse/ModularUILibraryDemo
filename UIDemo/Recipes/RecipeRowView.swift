//
//  RecipeRowView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/16/25.
//


import SwiftUI
import ModularUILibrary
    
    struct RecipeRowView: View {
        // Suppose the parent passed us a Binding<RecipeItem>:
        @ObservedObject var item: RecipeItem
        let onToggleFavorite: () -> Void
        //        @State var image: Image?
        @EnvironmentObject private var nav: AppNavigation
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
//        @EnvironmentObject var memoryStore: RecipeDataSource
        
//        @Binding var recipeMemory: Bool {
//            bindingFor(memoryStore.getMemory(for: item.sourceURL!))
//        }
        
        var body: some View {
            
            FeatureItem(
                title: item.name,
                description: item.cuisine,
                action: {
                    print("action fire for item")
                    nav.path.append(.recipeDetail(item.id))
                },
                leading: {
                    ImageContainer(image: $item.image, size: dynamicTypeSize.photoDimension, accessibilityId: item.id.uuidString)
                        .equatable()
                        .onAppear{
                            print("i appear imagecontainer with image \(item.image != nil)")
                        }
                },
                trailing: {
                    //                        let memory = $memoryStore.memories[url.absoluteString]
                    ToggleIconButton(
                        iconOn: .system("star"),
                        iconOff: .system("star.fill"),
                        isDisabled: .constant(false),
                        isSelected: $item.isFavorite) {
                            onToggleFavorite()
                        }
                    .asStandardIconButtonStyle(withColor: .yellow)
                    .accessibilityLabel(Text("ToggleIconButton: \(item.id.uuidString)"))
                    
                    
                    //                    VStack {
                    //                        if let url = item.sourceURL, memoryStore.getMemory(for: url).isFavorite {
                    //                            Image(systemName: "star.fill")
                    //                                .foregroundColor(.yellow)
                    //                        } else {
                    //                            Image(systemName: "star.fill")
                    //                                .foregroundColor(.black.opacity(0.4))
                    //                        }
                    //                    }
                    //                    .simultaneousGesture(newGesture, including: .all)
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
        
//        func bindingFor(_ item: Bool) -> Binding<Bool> {
//            Binding<Bool>(
//                get: {
//                    // read from your store
//                    item.isFavorite
////                    memoryStore.getMemory(for: url).isFavorite
//                },
//                set: { newValue in
//                    
//                    print("this is where i thought it would \(newValue)")
//                    item.isFavorite = newValue
//                    // write *that* back into the store
////                                    memoryStore.setFavorite(newValue, for: url)
//                }
//            )
//        }
    }
