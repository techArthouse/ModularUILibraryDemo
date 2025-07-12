//
//  CustomErrors.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/12/25.
//

import SwiftUI
import UIKit

// MARK: - Error cases for FetchCache
indirect enum FetchCacheError: Error {
    case failedToFindImageFromSystemMemoryBanks
    case failedToFetchImageFrom(source: URL, withError: FetchCacheError)
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
    case taskCancelled
    
    // following errors are related. our use is that when we catch `failedToInitializeDiskMemory` it will nest a more verbose error
    case failedToInitializeDiskMemory(withError: FetchCacheError) // root error for any but usually one of the following
    case noURLsFoundInDirectory(FileManager.SearchPathDirectory)
    case invalidPathForCacheURL(String)
    case directoryAlreadyOpenWithPathComponent(String)
    case fileManagerError(withURL: URL)

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

// MARK: - FetchCacheError Localized strings for description

extension FetchCacheError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToFindImageFromSystemMemoryBanks:
            return "Failed to find image in memory cache."

        case .failedToInitializeDiskMemory(let error):
            return "Could not initialize disk cache directory with error: \(error.localizedDescription)"

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
        case .taskCancelled:
            return "Call to network was cancelled"
        case .noURLsFoundInDirectory(let searchPath):
            return "No valid URLs found for directory \(searchPath)."
        case .invalidPathForCacheURL(let path):
            return "Cannot create disk system URL with invalid path component: \(path)"
        case .directoryAlreadyOpenWithPathComponent(let path):
            return "a cachDirectory with path \(path) is already open"
        case .fileManagerError(let url):
            return "File Manager Error: `createDirectory` failed at: \(url.absoluteString)"
        case .failedToFetchImageFrom(source: let source, withError: let withError):
            return "failed to fetch image for \(source.absoluteString) with error: \(withError.localizedDescription)"
        }
    }
}

// MARK: - Error cases for ImageError

enum ImageError: Error {
    case invalidData
}

// MARK: - Error cases for NetworkService

enum NetworkError: Error {
    case statusCodeFailure(Int)
    case malformedHTTPResponse
    case generalURLError(URLError)
    case unknownError(Error)
    case taskCancelled(URL)
}

// MARK: - NetworkError Localized strings for description

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .statusCodeFailure(let code):
            return "Server returned an unexpected status code: \(code)."
        case .malformedHTTPResponse:
            return "The server response was not a valid HTTP response."
        case .generalURLError(let urlError):
            return urlError.localizedDescription
        case .unknownError(let error):
            return "An unknown network error occurred: \(error.localizedDescription)"
        case .taskCancelled(let url):
            return "Task was cancelled for url request. Address: \(url.absoluteString)"
        }
    }
}


enum RecipeDecodeError: LocalizedError {
    case requiredFieldMissingOrMalformed(Error, [String: Any])
    case invalidJsonObject([String: Any])
    case dataURLError
    case unexpectedErrorWithDataModel(String)
    
    var errorDescription: String? {
        switch self {
        case .requiredFieldMissingOrMalformed(let e, let dict):
            return "Required data field is missing or malformed. Error: \(e.localizedDescription) for \(dict.debugDescription)"
        case .invalidJsonObject(let dict):
            return "JsonSerialization error for invalid json object: \(dict.debugDescription)"
        case .dataURLError:
            return "Error occured attempting to form data url."
        case .unexpectedErrorWithDataModel(let message):
            return message
        }
    }
}
