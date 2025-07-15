//
//  FakeImageCache.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/14/25.
//

import XCTest
import SwiftUI
@testable import UIDemo

@MainActor
internal class FakeImageCache: ImageCacheProtocol {
    func loadImage(for url: URL) async -> Result<Image, FetchCacheError> {
        .success(Image("square.and.arrow.up"))
    }
    
    func openCacheDirectoryWithPath(path: String) throws(FetchCacheError){
        // nothing yet
    }
    func refresh() async { didRefresh = true }
    
    private(set) var didRefresh = false
    func getImage(for url: URL) async throws -> Image { Image(systemName: "square.and.arrow.up") }
}

