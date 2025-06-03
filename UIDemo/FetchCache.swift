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
//    @State var isLoaded: Bool = false
    
    private var memoryCache = [String: Image]() //  in‐memory cache
    private var diskMemoryURL: URL? // directory on disk via URL
    
    private init() {
        print("loading cache first time")
        loadIfNeeded()
    }
    
    private func loadIfNeeded() {
        guard diskMemoryURL == nil else { return }
        do {
            try initializeDiskMemory() // maybe make it a optional init if folder fails to start?
        } catch {
            print(error.localizedDescription)
            
        }
        print("done loading")
    }
    
    private func initializeDiskMemory() throws {
        let cachesDirectory = FileManager.SearchPathDirectory.cachesDirectory
        guard let cachesBase = FileManager.default
                .urls(for: cachesDirectory, in: .userDomainMask)
                .first
        else {
            throw FetchCacheError.noURLsFoundInDirectory(cachesDirectory)
        }

        // Pick the correct folder name:
        #if DEBUG
        let cacheDirectoryURL = cachesBase.appendingPathComponent(
            "DevelopmentFetchImageCache",
            isDirectory: true
        )
        #else
        let cacheDirectoryURL = cachesBase.appendingPathComponent(
            "FetchImageCache",
            isDirectory: true
        )
        #endif

        // cache path exists or else create it.
        if FileManager.default.fileExists(atPath: cacheDirectoryURL.path)
            || (try? FileManager.default.createDirectory(
                   at: cacheDirectoryURL,
                   withIntermediateDirectories: true
               )) != nil
        {
            diskMemoryURL = cacheDirectoryURL
            print("Cache folder ready at \(cacheDirectoryURL.absoluteString)")
        } else {
            throw FetchCacheError.failedToInitializeDiskMemory
        }
    }
    
    
    /// Creates an encoded string from the sourceURL and appends it to cacheDirectoryURL that results local file url.
    func getElementDiskMemoryURL(using elementSourceURL: URL) throws(FetchCacheError) -> URL {
        guard let cacheDirectoryURL = diskMemoryURL
        else {
            throw FetchCacheError.cachedDirectoryURLisNil
        }
        
        guard let pathAddress = elementSourceURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else {
            throw FetchCacheError.failedToAppendEncodedRemoteURLToCacheDirectoryURL(remoteURL: elementSourceURL, cacheDirectoryURL: cacheDirectoryURL)
        }
        
        return cacheDirectoryURL.appendingPathComponent(pathAddress, conformingTo: .jpeg)
    }
    
    func getImageFor(url networkSourceURL: URL) async throws -> Image? {
        do {
            let localFileURL = try getElementDiskMemoryURL(using: networkSourceURL) // the url tied to this remote source and used as key to store and lookup
            
            loadIfNeeded() // follow from here and ask why it always request from network even after previously loading
            if let image = checkLocalMemory(using: networkSourceURL) { // if in local memory then we've already saved to disk
                return image
            } else if let image = try await checkDiskMemory(localFileURL: localFileURL) {  // if in disk, lets load to localmemory
                memoryCache[networkSourceURL.absoluteString] = image // at to mem
                return image
            } else { // if nil then lets ask network for new image and save (implicity overwrite source in disk if exists)
                let image = try await requestImageFromNetwork(at: networkSourceURL, saveTo: localFileURL, using: .get)
                memoryCache[networkSourceURL.absoluteString] = image
                return image
            }
            
        } catch {
//            switch e {
//            case .failedToGetImageFromNetworkRequest(_):
//                <#code#>
//            case .failedToConvertDataBlobToImage(sourceURL: let sourceURL, blob: let blob, sourceLocation: let sourceLocation):
//                <#code#>
//            case .failedToGetDataFromContentsOf(sourceURL: let sourceURL, sourceLocation: let sourceLocation):
//                <#code#>
//            default:
//                
//            }
            // if we ould not retrieve an image then we'll log whatever the error is and default to callers logic where no image can get retrieved
            print("\(error.localizedDescription)")
            return nil
        }
    }
    
//    func getImageFor(url sourceURL: URL) async throws -> Image {
//        do {
//            let localFileURL = getElementDiskMemoryURL(using: sourceURL) // the url tied to this remote source and used as key to store and lookup
//            if let image = try await loadImageFromSystemMemory(using: sourceURL) {
//                print("loadImageFromSystemMemory loadImageFromSystemMemory loadImageFromSystemMemory loadImageFromSystemMemory")
//                return image
//            } else {
//                // This can throw FetchCacheError (or, if something slips through, another Error).
//                return try await requestImageFromNetwork(at: sourceURL, using: .get)
//            }
//        } catch let e as FetchCacheError {
//            switch e {
//            case .failedToFindImageFromSystemMemoryBanks:
//                <#code#>
//            case .failedToInitializeDiskMemory:
//                <#code#>
//            case .failedToGetImageFromNetworkRequest(_):
//                <#code#>
//            case .failedToWriteImageDataToDisk(let image, _):
//                // Although we failed the logic in the throw happens aftger we successfully built an image
//                // from the net data but your disk image failed. hence, we still have an image we can display.
//                return image
//            case .dataConversionToImageFailed(_):
//                <#code#>
//            case .noURLsFoundInDirectory(_):
//                <#code#>
//            }
//            print("womp womp womp womp womp womp womp womp womp womp womp womp womp womp womp womp womp womp womp ")
//            // If requestImageFromNetwork threw any FetchCacheError, show placeholder
//            return Image("imageNotFound")
//        } catch {
//            // This catches *all other* Errors that might slip out unexpectedly.
//            print("pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow pmow ")
//            return Image("placeHolder")
//        }
//    }
    
    // note now that I specivied systemmemory i need to create a method for network but i think requestImageFromNetwork will do
    // use this to first try to load locally when you get each recipe. if it doesn't find it it will load from network.
    // if all fail without an error then we could not load the image
//    func loadImageFromSystemMemory(using imageSourceURL: URL) async -> Image? {
//        loadIfNeeded() // follow from here and ask why it always request from network even after previously loading
//        if let image = checkLocalMemory(url: imageSourceURL) { // if in local memory then we've already saved to disk
//            return image
//        } else if let image = await checkDiskMemory(using: imageSourceURL) { // if in disk, lets load to localmemory
//            memoryCache[imageSourceURL.absoluteString] = image // at to mem
//            return image
//        } else {
//            return nil
//        }
//    }
    
    /// throws FetchCacheError if failure, otherwise returns image found
    func requestImageFromNetwork(at networkSourceURL: URL, saveTo localFileURL: URL, using method: NetworkService.HTTPMethodType = .get ) async throws -> Image {
        do {
            let imageDataBlob = try await NetworkService.shared.requestData(from: networkSourceURL, using: method) // may throw NetworkError
            
            // image will be nil only if .imageIfImageData fails to load data as Image
            if let image = imageDataBlob.imageIfImageData {
                do {
                    // save data to disk directory using local file url
                    try imageDataBlob.write(to: localFileURL, options: .atomic)
                    print("Successfully wrote image to disk at \(localFileURL).  Cache size: \(memoryCache.count)")
                } catch {
                    print("\(error.localizedDescription)")
                    // fallthrough sincew we have an image to send back.
                    // throw FetchCacheError.failedToWriteImageDataToDisk(image: image, error: error)
                }
                return image
            } else {
                throw FetchCacheError.failedToConvertDataBlobToImage(sourceURL: networkSourceURL, blob: imageDataBlob, sourceLocation: .remote)
            }
        } catch let e as NetworkError {
            print("FetchCache - NetworkError: \(e.localizedDescription)")
            throw FetchCacheError.failedToGetImageFromNetworkRequest(e)
        } catch let e as FetchCacheError {
            throw e
        }
    }
    
    func refresh() {
        deleteDiskMemory()
        deleteLocalMemory()
        
        // reset directoryurl to remove stale path
        diskMemoryURL = nil
        print("i feel fresh and diskMemURL is nil: \(diskMemoryURL == nil)")
        loadIfNeeded()
//        objectWillChange.send()
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
        
        memoryCache.removeAll()
    }
}

// MARK: - methods for local fetches of images/data

extension FetchCache {
    func checkLocalMemory(using remoteSourceURL: URL) -> Image? {
        memoryCache[remoteSourceURL.absoluteString] // simple check for element. subscript safely returns nil if optional force unwrap fails.
    }
    
    func checkDiskMemory(localFileURL: URL) async throws(FetchCacheError) -> Image? {
        // if the left chec passes, but the second one does then all we can do is try the network call to see if we can get a new valid image
        guard FileManager.default.fileExists(atPath: localFileURL.path()), let data = try? Data(contentsOf: localFileURL) else {
            return nil
        }
        if let image = data.imageIfImageData { // if data fails cause url can't be read or an error threw, return nil otherwise element.
            return image
        } else {
            throw FetchCacheError.failedToConvertDataBlobToImage(sourceURL: localFileURL, blob: data, sourceLocation: .local)
        }
    }
}

enum FetchCacheError: Error {
    case failedToFindImageFromSystemMemoryBanks
    case failedToInitializeDiskMemory
    case failedToGetImageFromNetworkRequest(NetworkError)
    case failedToGetDataFromContentsOf(sourceURL: URL, sourceLocation: URLSource)
    case failedToWriteImageDataToDisk(image: Image, error: Error)
    case failedToAppendEncodedRemoteURLToCacheDirectoryURL(
        remoteURL: URL,
        cacheDirectoryURL: URL
    )
    case failedToConvertDataBlobToImage(
        sourceURL: URL,
        blob: Data,
        sourceLocation: URLSource
    )
    case cachedDirectoryURLisNil
    case noURLsFoundInDirectory(FileManager.SearchPathDirectory)

    enum URLSource {
        case local
        case remote
        
        var description: String {
            switch self {
            case .local:
                "local disk"
            case .remote:
                "remote URL"
            }
        }
    }
}

// MARK: — Conform to LocalizedError
extension FetchCacheError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToFindImageFromSystemMemoryBanks:
            return "Failed to find image in memory cache."

        case .failedToInitializeDiskMemory:
            return "Could not initialize disk cache directory."

        case .failedToGetImageFromNetworkRequest(let networkError):
            // Use the underlying NetworkError’s localizedDescription.
            return """
                   Failed to fetch image from network:
                   \(networkError.localizedDescription)
                   """

        case .failedToGetDataFromContentsOf(let sourceURL, let sourceLocation):
            let locationDesc = (sourceLocation == .local) ? "local disk" : "remote URL"
            return """
                   Failed to load data from \(locationDesc):
                   URL = \(sourceURL.absoluteString)
                   """

        case .failedToWriteImageDataToDisk(_, let underlyingError):
            // We don't need to show the Image, just include the error detail.
            return "Failed to write image data to disk: \(underlyingError.localizedDescription)"

        case .failedToAppendEncodedRemoteURLToCacheDirectoryURL(
                let remoteURL,
                let cacheDirectoryURL
            ):
            return """
                   Could not form a valid cache filename for remote URL.
                   remoteURL = \(remoteURL.absoluteString)
                   cacheDirectory = \(cacheDirectoryURL.path)
                   """

        case .failedToConvertDataBlobToImage(let sourceURL, let blob, let sourceLocation):
            let locationDesc = (sourceLocation == .local) ? "disk" : "network"
            return """
                   Data at \(locationDesc) URL could not be converted into an Image:
                   sourceURL = \(sourceURL.absoluteString)
                   blob size = \(blob.count) bytes
                   """

        case .cachedDirectoryURLisNil:
            return "Cache directory URL was unexpectedly nil."

        case .noURLsFoundInDirectory(let searchPath):
            return "No valid URLs found for directory \(searchPath)."
        }
    }
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
