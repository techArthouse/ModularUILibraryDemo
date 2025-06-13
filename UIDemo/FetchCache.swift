//
//  FetchCache.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import UIKit

@MainActor
class FetchCache: ObservableObject {
    static let shared = FetchCache()
    
    private var memoryCache = [String: Image]() //  in‐memory cache
    private var diskMemoryURL: URL? // directory on disk via URL
    /// Track when each URL was last fetched (in-memory or on-disk).
    private var lastFetchDates = [String: Date]()
    
    private init() { }
    
    /// Helper Method to open the cacheDirectory for FetchCache. If cache already has an open directory then error is thrown.
    func openCacheDirectoryWithPath(path: String) throws(FetchCacheError) {
        if let diskMemoryCacheURL = diskMemoryCacheAlreadyExists() {
            throw FetchCacheError.directoryAlreadyOpenWithPathComponent(diskMemoryCacheURL.lastPathComponent)
        }
        try initializeDiskMemory(with: path)
    }
    
    /// if FetchCache diskmemoryurl already exists then the url is returned. nil if it does not exist.
    private func diskMemoryCacheAlreadyExists() -> URL? {
        do {
            guard let url = diskMemoryURL else {
                return nil
            }
            if FileManager.default.fileExists(atPath: url.path()) {
                return url
            } else {
                return nil
            }
        }
    }
    
    private func baseDirectoryURLForDomainCache() throws(FetchCacheError) -> URL {
        let cachesDirectory = FileManager.SearchPathDirectory.cachesDirectory
        guard let cachesBase = FileManager.default
            .urls(for: cachesDirectory, in: .userDomainMask)
            .first
        else {
            throw FetchCacheError.noURLsFoundInDirectory(cachesDirectory)
        }
        return cachesBase
    }
    
    private func loadCacheDirectory(at cacheDirectoryURL: URL) throws(FetchCacheError) {
        do {
            try FileManager.default.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
            diskMemoryURL = cacheDirectoryURL
        } catch {
            throw FetchCacheError.fileManagerError(withURL: cacheDirectoryURL)
        }
    }
    
    private func initializeDiskMemory(with pathComponent: String) throws(FetchCacheError) {
        guard pathComponent.isContiguousUTF8 else {
            throw FetchCacheError.invalidPathForCacheURL(pathComponent)
        }
        
        let cacheDomainBaseURL = try baseDirectoryURLForDomainCache()
        let cacheDirectoryURL = cacheDomainBaseURL.appendingPathComponent(
            pathComponent,
            isDirectory: true
        )
        
        try loadCacheDirectory(at: cacheDirectoryURL)
    }
    
    /// Creates an encoded string from the sourceURL and appends it to cacheDirectoryURL that results local file url.
    /// Can throw `FetchCacheError` of types: `cachedDirectoryURLisNil` or `failedToAppendEncodedRemoteURLToCacheDirectoryURL`
    private func generateElementURLFromDiskMemoryURL(using elementSourceURL: URL) throws(FetchCacheError) -> URL {
        guard let cacheDirectoryURL = diskMemoryURL
        else {
            throw FetchCacheError.cachedDirectoryURLisNil
        }
        
        guard let pathAddress = elementSourceURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        else {
            throw FetchCacheError.failedToAppendEncodedRemoteURLToCacheDirectoryURL(remoteURL: elementSourceURL, cacheDirectoryURL: cacheDirectoryURL)
        }
//        print("elementsourceurl.path() encoded: \(elementSourceURL.path())")
//        print("elementsourceurl.path() not encoded: \(elementSourceURL.path(percentEncoded: false))")
//        print("elementsourceurl.absolutString: \(elementSourceURL.absoluteString)")
//        print("elementsourceurl.absolutString.addingPercentEncoding(withAllowedCharacters: .alphanumerics): \(elementSourceURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "wtfhappened")")
//        let pathAddress = elementSourceURL.path(percentEncoded: false)
//        print("path address is: \(pathAddress), and cachedDir is \(cacheDirectoryURL.absoluteString)")
        let url = cacheDirectoryURL.appendingPathComponent(pathAddress, isDirectory: false)
        return url
    }
    
    /// returns image from source or
    func getImageFor(url networkSourceURL: URL) async throws(FetchCacheError) -> Image {
        do {
            try? await Task.sleep(for: .seconds(3)) // for testing purposes to visually see the loads
            
            if let image = checkLocalMemory(using: networkSourceURL) { // if in local memory then we've already saved to disk
                return image
            } else {
                let localFileURL = try generateElementURLFromDiskMemoryURL(using: networkSourceURL) // the url tied to this remote source and used as key to store and lookup
                if let image = try await checkDiskMemory(localFileURL: localFileURL) { // if in disk, lets load to localmemory
                    memoryCache[networkSourceURL.absoluteString] = image // at to mem
                    return image
                } else { // if nil then lets ask network for new image and save (implicity overwrite source in disk if exists)
                    let image = try await requestImageFromNetwork(at: networkSourceURL, saveTo: localFileURL, using: .get)
                    memoryCache[networkSourceURL.absoluteString] = image
                    return image
                }
            }
        } catch {
            // if we ould not retrieve an image then we'll log whatever the error is and default to callers logic where no image can get retrieved
            print("\(error.localizedDescription)")
            
            switch error {
            case .failedToWriteImageDataToDisk(image: let image, _):
                // still save it to cache for curret instance.
                memoryCache[networkSourceURL.absoluteString] = image
                return image
            case .cachedDirectoryURLisNil: // this error might be good to restart from the client since it's the base requirement to not have non existant cache
                throw FetchCacheError.failedToFetchImageFrom(source: networkSourceURL, withError: error)
            case .failedToAppendEncodedRemoteURLToCacheDirectoryURL: // this one might be worth catching at client so they can validate they are passing correct string
                throw FetchCacheError.failedToFetchImageFrom(source: networkSourceURL, withError: error)
            case .failedToGetDataFromContentsOf, .failedToConvertDataBlobToImage, .failedToGetImageFromNetworkRequest: // these are fatal since process seems corrupted
                throw FetchCacheError.failedToFetchImageFrom(source: networkSourceURL, withError: error)
            case .taskCancelled:
                throw FetchCacheError.taskCancelled
            default:
                throw FetchCacheError.failedToFetchImageFrom(source: networkSourceURL, withError: error) // unless i expanbd on the previous cases maybe they should default to throw original error only .failedToWriteImageDataToDisk would still give us an image we can send back.
            }
        }
    }
    
    /// throws FetchCacheError if failure, otherwise returns image found
    private func requestImageFromNetwork(
        at networkSourceURL: URL,
        saveTo localFileURL: URL,
        using method: NetworkService.HTTPMethodType = .get)
    async throws(FetchCacheError) -> Image {
        var imageDataBlob: Data
        do {
            imageDataBlob = try await NetworkService.shared.requestData(from: networkSourceURL, using: method) // may throw NetworkError
        } catch let e {
            print("FetchCache - NetworkError: \(e.localizedDescription)")
            switch e {
            case .taskCancelled:
                throw FetchCacheError.taskCancelled
            default:
                throw FetchCacheError.failedToGetImageFromNetworkRequest(e)
            }
        }
        
        // image will be nil only if .imageIfImageData fails to load data as Image
        if let image = imageDataBlob.imageIfImageData {
            do {
                // save data to disk directory using local file url
                try imageDataBlob.write(to: localFileURL, options: .atomic)
                print("Successfully wrote image to disk at \(localFileURL).  Cache size: \(memoryCache.count)")
            } catch {
                print("\(error.localizedDescription)")
                throw FetchCacheError.failedToWriteImageDataToDisk(image: image, error: error)
            }
            return image
        } else {
            throw FetchCacheError.failedToConvertDataBlobToImage(sourceURL: networkSourceURL, blob: imageDataBlob, sourceLocation: .remote)
        }
    }
    
    func refresh() async {
        guard let diskMemoryCacheURLPath = diskMemoryCacheAlreadyExists()?.lastPathComponent else {
            return
        }
        
        deleteLocalMemory()
        deleteDiskMemory()
        print("refresh delete diskandlocal mem")
        
        do {
            try initializeDiskMemory(with: diskMemoryCacheURLPath) // maybe make it a optional init if folder fails to start?
        } catch {
            /// TODO: In the future we should thow the error so caller can make informed step.
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Operations
    
    private func deleteDiskMemory() {
        guard let diskMemoryURL = diskMemoryURL else { return }
        do {
            try FileManager.default.removeItem(at: diskMemoryURL) // delete system app mem
            self.diskMemoryURL = nil
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
    private func checkLocalMemory(using remoteSourceURL: URL) -> Image? {
        memoryCache[remoteSourceURL.absoluteString] // simple check for element. subscript safely returns nil if optional force unwrap fails.
    }
    
    //
    private func checkDiskMemory(localFileURL: URL) async throws(FetchCacheError) -> Image? {
        guard FileManager.default.fileExists(atPath: localFileURL.path()) else {
            return nil
        }
        guard let data = try? Data(contentsOf: localFileURL) else {
            throw FetchCacheError.failedToGetDataFromContentsOf(sourceURL: localFileURL, sourceLocation: .local)
        }
        return data.imageIfImageData
    }
}
