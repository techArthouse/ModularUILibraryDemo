//
//  LandingView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//


import SwiftUI
import ModularUILibrary

// MARK: - Navigation State

enum Tab: Hashable {
    case home, favorites, profile
}

enum Route: Hashable {
    case recipes
    case recipeDetail(Recipe)
}

// MARK: - Landing Page

struct LandingView: View {
    @EnvironmentObject var nav: AppNavigation

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Fetch Recipes")
                .font(.largeTitle).bold()
            Spacer()
            
            Button(action: {
                nav.path.append(.recipes)
            }) {
                Text("View Recipes")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .padding()
    }
}

 
//    func getRecipeImage(for recipeItem: Binding<RecipeItem>) async  {
//        await FetchCache.shared.getImageFor(url: url)
//    }

    /// Drop both image memory & disk caches, and clear each item’s image
//    func refreshAll() {
//        FetchCache.shared.refresh()
//        for item in items {
//            item.image = Image(systemName: "heart")
//        }
//    }



// MARK: - Recipe Detail View







// MARK: - Root ContentView


// MARK: - Utilities (Proxy for scroll)

// Simple proxy to hold reference to the ScrollViewReader proxy
final class ScrollViewProxy {
    static let shared = ScrollViewProxy()
    var proxy: ScrollViewProxy? = nil
    func scrollToTop() {
        // implement scrolling logic here
    }
}

// MARK: - Video Player Placeholder
import AVKit
struct VideoPlayerView: View {
    let url: URL
    //    var body: some View {
    //        Text("Video player for: \(url.absoluteString)")
    //    }
    @State var player: AVPlayer = AVPlayer()
    @State var isPlaying: Bool = false
    
    init(url: URL) {
        self.url = url
//        self.player = AVPlayer(url: url)
        self.isPlaying = false
    }
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .frame(width: 320, height: 180, alignment: .center)
                .onAppear {
//                                let url = URL(string: "https://www.youtube.com/embed/4vhcOwVBDO4")!
//                    print("https://www.youtube.com/embed/\(extractStringAfterV(from: url.absoluteString)!)")
                    let url = URL(string: "https://www.youtube.com/embed/\(extractStringAfterV(from: url.absoluteString)!)")!
//                    print("\(url.absoluteString)")
//                    player = AVPlayer(url: url.absoluteURL)
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
//                    player.currentItem = AVPlayerItem(url: url)
//                                player.play()
                                
                            }
            
            
//            Button {
//                isPlaying ? player.pause() : player.play()
//                isPlaying.toggle()
//                player.seek(to: .zero)
//            } label: {
//                Image(systemName: isPlaying ? "stop" : "play")
//                    .padding()
//            }
        }
    }

    func extractStringAfterV(from inputString: String) -> String? {
        // Define the regex pattern: "v=" followed by a capturing group (.*)
        // The capturing group (.*) matches any character (except newline) zero or more times.
        let regex = /v=(.*)/

        // Attempt to match the regex against the input string.
        // Use `firstMatch` to find the first occurrence of the pattern.
        if let match = inputString.firstMatch(of: regex) {
            // The captured substring is available in the `match` result.
            // Access the first captured group (index 1) which contains the string after "v=".
            return String(match.output.1)
        } else {
            // No match found.
            return nil
        }
    }
}

import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    
    private let url: URL
    @State var progress: Double = 0.0
    var isLoading: Binding<Bool>
    
    init?(videoID: String, isLoading: Binding<Bool>) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)") else { return nil }
        self.init(url: url, isLoading: isLoading)
    }
    
    init(url: URL, isLoading: Binding<Bool>){
        self.url = url
        self.isLoading = isLoading
        
    }
    
    // MARK: Functions

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        print("updateUIView")
        isLoading.wrappedValue = true
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
            var parent: YouTubePlayerView

            init(_ parent: YouTubePlayerView) {
                self.parent = parent
            }

            // WKNavigationDelegate methods for tracking loading status
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                print("didFinish")
                parent.isLoading.wrappedValue = false
            }

            func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
                print("didFail")
                parent.isLoading.wrappedValue = false
                // Handle error
            }

            // KVO observer for estimatedProgress
            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                if keyPath == "estimatedProgress" {
                    if let progress = object as? WKWebView {
                        parent.progress = progress.estimatedProgress
                    }
                }
            }
        }
}
