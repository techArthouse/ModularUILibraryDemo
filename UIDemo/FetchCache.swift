//
//  FetchCache.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import UIKit
import Foundation

@MainActor
class FetchCache: ObservableObject {
    static let shared = FetchCache()
    @State var isLoaded: Bool = false
    
    @State private var memoryCache = [String: Image]() //  in‐memory cache
    @State private var diskMemoryURL: URL? // directory on disk via URL
    
    private init() {
        print("loading cache first time")
        loadIfNeeded()
    }
    
    private func initializeDiskMemory() throws {
        // Load folder name/address
        let cachesDirectory = FileManager.SearchPathDirectory.cachesDirectory
        if let cachesBase = FileManager.default.urls(for: cachesDirectory, in: .userDomainMask).first {
            var cacheDirectoryURL: URL
            #if DEBUG
                cacheDirectoryURL = cachesBase.appendingPathComponent("DevelopmentFetchImageCache", isDirectory: true)
            #else
                cacheDirectoryURL = cachesBase.appendingPathComponent("FetchImageCache", isDirectory: true)
            #endif
            
            if FileManager.default.fileExists(atPath: cacheDirectoryURL.path())
                || ((try? FileManager.default.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)) != nil)
            {
                diskMemoryURL = cacheDirectoryURL
            } else {
                throw FetchCacheError.failedToInitializeDiskMemory
            }
        } else {
            throw FetchCacheError.noURLsFoundInDirectory(cachesDirectory)
        }
    }
    
    func getElementDiskMemoryURL(using elementSourceURL: URL) -> URL? {
        guard
            let persistedFolder = diskMemoryURL,
            let pathAddress = elementSourceURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        else {
            return nil
        }
        
        return persistedFolder.appendingPathComponent(pathAddress, conformingTo: .image)
    }
    
//    note now that I specivied systemmemory i need to create a method for network but i think requestImageFromNetwork will do
    // use this to first try to load locally when you get each recipe. if it doesn't find it it will load from network.
    // if all fail without an error then we could not load the image
    func loadImageFromSystemMemory(using imageSourceURL: URL) async -> Image? {
        loadIfNeeded()
        if let image = checkLocalMemory(url: imageSourceURL) { // if in local memory then we've already saved to disk
            return image
        } else if let image = await checkDiskMemory(using: imageSourceURL) { // if in disk, lets load to localmemory
            memoryCache[imageSourceURL.absoluteString] = image // at to mem
            return image
        } else {
            return nil
        }
    }
    
    /// throws FetchCacheError if failure, otherwise returns image found
    func requestImageFromNetwork(at networkSourceURL: URL, using method: NetworkService.HTTPMethodType = .get ) async throws -> Image {
        do {
            let imageDataBlob = try await NetworkService.shared.requestData(from: networkSourceURL, using: method)
            
            // image will be nil only if .imageIfImageData fails to load data as Image
            if let image = imageDataBlob.imageIfImageData {
                memoryCache[networkSourceURL.absoluteString] = image

                // 1) compute a local file URL from your disk cache directory
                if let localURL = getElementDiskMemoryURL(using: networkSourceURL) {
                    try imageDataBlob.write(to: localURL, options: .atomic)
                }
                return image
            } else {
                throw FetchCacheError.dataConversionToImageFailed(networkSourceURL)
            }
        } catch let e as NetworkError {
            print("FetchCache - NetworkError: \(e.localizedDescription)")
            throw FetchCacheError.failedToGetImageFromNetworkRequest(e)
        } catch let e as FetchCacheError {
            throw e
        } catch {
            assertionFailure("FetchCache - Uncaught Error from Network request")
            throw FetchCacheError.failedToGetImageFromNetworkRequest(.unkownError(error)) // in order to safely exit if unexpected error caught
        }
    }
    
    func getImageFor(url sourceURL: URL) async -> Image {
        do {
            if let image = await loadImageFromSystemMemory(using: sourceURL) {
                return image
            } else {
                // This can throw FetchCacheError (or, if something slips through, another Error).
                return try await requestImageFromNetwork(at: sourceURL, using: .get)
            }
        } catch is FetchCacheError {
            // If requestImageFromNetwork threw any FetchCacheError, show placeholder
            return Image("placeHolder")
        } catch {
            // This catches *all other* Errors that might slip out unexpectedly.
            return Image("placeHolder")
        }
    }
    
    private func loadIfNeeded() {
        guard diskMemoryURL == nil else { return }
        do {
            try initializeDiskMemory() // maybe make it a optional init if folder fails to start?
        } catch {
            print(error)
        }
        print("done loading")
    }
    
    func refresh() {
        deleteDiskMemory()
        deleteLocalMemory()
        
        // reset directoryurl to remove stale path
        diskMemoryURL = nil
        loadIfNeeded()
        print("i feel fresh")
        objectWillChange.send()
    }
    
    // MARK: - Delete Operations
    
    private func deleteDiskMemory() {
        guard let diskMemoryURL = diskMemoryURL else { return }
        do {
            try FileManager.default.removeItem(at: diskMemoryURL) // delete system app mem
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func deleteLocalMemory() {
        guard !memoryCache.isEmpty else { return }
        
        memoryCache.removeAll(keepingCapacity: true)
    }
}

// MARK: - methods for local fetches of images/data

extension FetchCache {
    func checkLocalMemory(url: URL?) -> Image? {
        memoryCache[url!.absoluteString] // simple check for element. subscript safely returns nil if optional force unwrap fails.
    }
    
    func checkDiskMemory(using elementSourceURL: URL?) async -> Image? {
        guard
            let sourceURL = elementSourceURL,
            let diskMemoryURL = getElementDiskMemoryURL(using: sourceURL) else {
            return nil
        }
        
        // These two lines are equivalent to having wrapped this in a do/catch to listen for data throws where we would return nil
        // if neither found or error
        let data = try? Data(contentsOf: diskMemoryURL)
        return data?.imageIfImageData // if data fails cause url can't be read or an error threw, return nil otherwise element.
    }
}

enum FetchCacheError: Error {
    case failedToFindImageFromSystemMemoryBanks
    case failedToInitializeDiskMemory
    case failedToGetImageFromNetworkRequest(NetworkError)
    case dataConversionToImageFailed(URL)
    case noURLsFoundInDirectory(FileManager.SearchPathDirectory)
}

enum ImageError: Error {
    case invalidData
}

enum NetworkError: Error {
    case statusCodeFailure(Int)
    case malformedHTTPResponse
    case generalURLError(URLError)
    case unkownError(Error)
}

extension Data {
    public var imageIfImageData: Image? {
        guard let uiImage = UIImage(data: self) else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }
}
