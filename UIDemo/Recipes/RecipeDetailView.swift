//
//  RecipeDetailView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/12/25.
//

import SwiftUI
import UIKit
import ModularUILibrary
import SafariServices

struct RecipeDetailView: View {
    @ObservedObject var item: RecipeItem
    let onToggleFavorite: () -> Void
    @State private var image: Image?
    @State private var source: URLType? = nil
    @State private var isLoading: Bool = false
    
    enum URLType: Identifiable {
        public var id: URL {
            switch self {
            case .video(let url), .webPage(let url):
                    return url
            }
        }
        
        case video(URL)
        case webPage(URL)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: — Title
                    Text(item.name)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.vertical)
                
                // MARK: — Image + Cuisine + favorite
                ZStack {
                    ImageCard(image: $image, size: nil, title: item.name, description: item.cuisine)
                        .task {
                            image = try? await FetchCache.shared
                                .getImageFor(url: item.smallImageURL!)
                        }
                    HStack(alignment: .top) {
                        Spacer()
                        VStack {
                            ToggleIconButton(
                                iconOn: .system("star"),
                                iconOff: .system("star.fill"),
                                isDisabled: .constant(false),
                                isSelected: $item.isFavorite) {
                                    onToggleFavorite()
                                }
                                .asStandardIconButtonStyle(withColor: .yellow)
                                .accessibilityLabel(Text("ToggleIconButton: \(item.id.uuidString)"))
                                .padding(.trailing)
                            Spacer()
                        }
                    }
                }
                
                // MARK: — Buttons
                VStack(spacing: 12) {
                    CTAButtonStack(.vertical) {
                        if let url = item.videoURL {
                            CTAButton(title: "Watch Video") {
                                //                                    showVideoSheet = true
                                source = .video(url)
                            }.asPrimaryButton(padding: .stacked)
                        }
                        if let sourceURL = item.sourceURL {
                            CTAButton(title: "View Full Recipe") {
                                //                                showSourceSheet = true
                                source = .webPage(sourceURL)
                            }.asSecondaryButton(padding: .stacked)
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        // YouTube sheet
        .sheet(item: $source) { source in
            VStack {
                switch source {
                case .video(let url):
                    if let videoID = extractStringAfterV(from: url.absoluteString) {
                        // MARK: — Title
                        Text(item.name)
                            .font(.largeTitle).bold()
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.top)
                        YouTubePlayerView(videoID: videoID, isLoading: $isLoading)
                        .scaledToFit()
                            .overlay {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.black.opacity(0.25))
                                }
                            }
                            //                        .ignoresSafeArea()
                        Spacer()
                    } else {
                        Text("Video unavailable")
                    }
                    
                case .webPage(let url):
                    SafariView(url: url)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    

    // Simple SafariView wrapper
    struct SafariView: UIViewControllerRepresentable {
        typealias UIViewControllerType = SFSafariViewController
        let url: URL
        
        func makeUIViewController(context: Context) -> SFSafariViewController {
            SFSafariViewController(url: url)
        }
        
        func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        }
        
        
    }

    // Regex helper as before
    func extractStringAfterV(from inputString: String) -> String? {
        let regex = /v=(.*)/
        if let match = inputString.firstMatch(of: regex) {
            return String(match.output.1)
        }
        return nil
    }
}

#Preview {
    let recipe = Recipe.recipePreview(using: .good)
    RecipeDetailView(item: RecipeItem(recipe: recipe!), onToggleFavorite: {})
        .task {
            
                do {
                    // Pick the correct folder name: "DevelopmentFetchImageCache" "FetchImageCache"
                #if DEBUG
                    try FetchCache.shared.openCacheDirectoryWithPath(path: "DevelopmentFetchImageCache")
                #else
                    try vm.startCache(path: "FetchImageCache")
                #endif
                } catch {
                    return
                    // failed to start cache. what do i do here? is vm.items = [] appropriate?
                }
        }
        .environmentObject(ThemeManager())
}
