//
//  FetchCache.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import UIKit

@MainActor
protocol ImageCacheProtocol {
    func loadImage(for url: URL) async -> Result<Image, ImageCacheError>
    func refresh() async
}


/// `CustomAsyncImageCache` a custom implementation of an async image cache.
/// Takes in a path to build the adresss where the images are cached in memory. Set once and share across modules or
/// better control what you cache and share.
@MainActor
class CustomAsyncImageCache: ObservableObject, ImageCacheProtocol {
    private let networkService: any NetworkServiceProtocol
    private var memoryCache = [String: Image]() // in‐memory cache
    private let path: String // The identity of the cache
    
    private lazy var systemCachesDirectory: URL? = {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first
    }()
    
    private var cacheDirectoryURL: URL? { // The root of the cache
        systemCachesDirectory?.appendingPathComponent(path, isDirectory: true)
    }
    
    init(path: String, networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
        self.path = path
        try? self.ensureCacheDirectoryExists()
    }
    
    /// Helper Method to open the cacheDirectory for CustomAsyncImageCache. If cache already has an open directory then error is thrown.
    internal func ensureCacheDirectoryExists() throws(ImageCacheError) {
        try initializeDiskMemory()
    }
    
    private func initializeDiskMemory() throws(ImageCacheError) {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            throw ImageCacheError.noURLsFoundInDirectory(FileManager.SearchPathDirectory.cachesDirectory)
        }
        
        try loadCacheDirectory(at: cacheDirectoryURL)
    }
    
    private func loadCacheDirectory(at cacheDirectoryURL: URL) throws(ImageCacheError) {
        do {
            try FileManager.default.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
        } catch {
            throw ImageCacheError.fileManagerError(withURL: cacheDirectoryURL)
        }
    }
    
    /// Creates an encoded string from the sourceURL and appends it to cacheDirectoryURL that results local file url.
    /// Can throw `FetchCacheError` of types: `cachedDirectoryURLisNil` or `failedToAppendEncodedRemoteURLToCacheDirectoryURL`
    private func makeFileURL(using elementSourceURL: URL) throws(ImageCacheError) -> URL {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            throw ImageCacheError.noURLsFoundInDirectory(FileManager.SearchPathDirectory.cachesDirectory)
        }

        guard let pathAddress = elementSourceURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw ImageCacheError.failedToEnodeURLString(remoteURL: elementSourceURL)
        }
        
        let url = cacheDirectoryURL.appendingPathComponent(pathAddress, isDirectory: false)
        return url
    }
    
    // MARK: - Public API
    
    /// returns image from source, local memory, or disk memory
    func loadImage(for url: URL) async -> Result<Image, ImageCacheError> {
        do {
            if let image = checkLocalMemory(using: url) {
                return .success(image)
            }

            let localFileURL = try makeFileURL(using: url)

            if let image = try await checkDiskMemory(localFileURL: localFileURL) {
                memoryCache[url.absoluteString] = image
                return .success(image)
            }

            let image = try await requestImageFromNetwork(at: url, saveTo: localFileURL)
            memoryCache[url.absoluteString] = image
            return .success(image)

        } catch {
            switch error {
            case .failedToWriteImageDataToDisk(let image, _):
                memoryCache[url.absoluteString] = image
                return .success(image)
            default:
                return .failure(error)
            }
        }
    }
    
    func refresh() async {
        deleteLocalMemory()
        deleteDiskMemory()
        Logger.log("refreshing image cache")
        
        do {
            try initializeDiskMemory()
        } catch {
            Logger.log(level: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Network calls
    
    /// throws FetchCacheError if failure, otherwise returns image found
    private func requestImageFromNetwork(at networkSourceURL: URL,
                                         saveTo localFileURL: URL,
                                         using method: NetworkService.HTTPMethodType = .get) async throws(ImageCacheError) -> Image {
        var imageDataBlob: Data
        do {
            imageDataBlob = try await networkService.requestData(from: networkSourceURL, using: method) // may throw NetworkError
        } catch let e {
            Logger.log(level: .error, "FetchCache - NetworkError: \(e.localizedDescription)")
            switch e {
            case .taskCancelled:
                throw ImageCacheError.taskCancelled
            default:
                throw ImageCacheError.failedToGetImageFromNetworkRequest(e)
            }
        }
        
        // image will be nil only if .imageIfImageData fails to load data as Image
        if let image = imageDataBlob.imageIfImageData {
            do {
                // save data to disk directory using local file url
                try imageDataBlob.write(to: localFileURL, options: .atomic)
                Logger.log("Successfully wrote image to disk at \(localFileURL).  Cache size: \(memoryCache.count)")
            } catch {
                Logger.log(level: .error, "\(error.localizedDescription)")
                throw ImageCacheError.failedToWriteImageDataToDisk(image: image, error: error)
            }
            return image
        } else {
            throw ImageCacheError.failedToConvertDataBlobToImage(sourceURL: networkSourceURL, blob: imageDataBlob, sourceLocation: .remote)
        }
    }
    
    // MARK: - Delete Operations
    
    private func deleteDiskMemory() {
        do {
            guard let cacheDirectoryURL = cacheDirectoryURL else {
                throw ImageCacheError.noURLsFoundInDirectory(FileManager.SearchPathDirectory.cachesDirectory)
            }
            try FileManager.default.removeItem(at: cacheDirectoryURL)
        } catch {
            Logger.log(level: .error, error.localizedDescription)
        }
    }
    
    private func deleteLocalMemory() {
        guard !memoryCache.isEmpty else { return }
        memoryCache.removeAll()
    }
}

// MARK: - methods for local fetches of images/data

extension CustomAsyncImageCache {
    private func checkLocalMemory(using remoteSourceURL: URL) -> Image? {
        memoryCache[remoteSourceURL.absoluteString] // simple check for element. subscript safely returns nil if optional force unwrap fails.
    }
    
    private func checkDiskMemory(localFileURL: URL) async throws(ImageCacheError) -> Image? {
        guard FileManager.default.fileExists(atPath: localFileURL.path()) else {
            return nil
        }
        guard let data = try? Data(contentsOf: localFileURL) else {
            throw ImageCacheError.failedToGetDataFromContentsOf(sourceURL: localFileURL, sourceLocation: .local)
        }
        return data.imageIfImageData
    }
}

// MARK: - DEBUG Structures

#if DEBUG
class MockFetchCache: ImageCacheProtocol {
    func loadImage(for url: URL) async -> Result<Image, ImageCacheError> {.success(
        Image(systemName: "heart.fill")
            .resizable()
            .renderingMode(.template))
    }
    
    func refresh() async {
        Logger.log("refreshing")
    }
    
    func ensureCacheDirectoryExists() throws(ImageCacheError) {
        Logger.log("mock fetchcache directory opened")
    }
}
#endif
