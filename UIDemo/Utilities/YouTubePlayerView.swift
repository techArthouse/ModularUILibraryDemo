//
//  YouTubePlayerView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//


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
