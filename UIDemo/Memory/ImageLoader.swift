//
//  ImageLoader.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/10/25.
//

import SwiftUI

/// Lightweight image loading component for any cache protocol
final class ImageLoader: ObservableObject {
    @Published var image: Image? = nil // Image component bound to view
    private let cache: ImageCacheProtocol
    private let url: URL?
    
    init(url: URL?, cache: ImageCacheProtocol) {
        self.url = url
        self.cache = cache
    }
    
    func load() async {
        guard let url = url else {
            self.image = Image("imageNotFound")
            return
        }
        
        let result = await cache.loadImage(for: url)
        switch result {
        case .success(let fetchedImage):
            Logger.log("successfully loaded image")
            self.image = fetchedImage
        case .failure(let error):
            Logger.log("Image loading failed: \(error.localizedDescription)")
            self.image = Image("imageNotFound")
        }
    }
}
