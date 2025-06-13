//
//  NetworkService.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import Foundation

final class NetworkService {
    static let shared: NetworkService = NetworkService()
    let statusCodeSuccessRange = Array(200...300) + Array(arrayLiteral: 304)
    
    private init() { }
    
    /// throws custom NetworkError for more control and relevant info to caller
    func requestData(from url: URL, using method: HTTPMethodType = .get) async throws(NetworkError) -> Data {
        do {
            // Before you do anything, respect any pending cancellation:
            try Task.checkCancellation()
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.malformedHTTPResponse
            }
            guard statusCodeSuccessRange.contains(http.statusCode) else {
                throw NetworkError.statusCodeFailure(http.statusCode)
            }
            return data
            
        } catch is CancellationError { // Throw cancelled error so callers can catch it explicitly
            throw NetworkError.taskCancelled(url)
        } catch let e as URLError { // Any error that comes from urlsession operation
            throw NetworkError.generalURLError(e)
        } catch let e as NetworkError { // a catch all for errors we throw.
            throw e
        } catch { // Any other error we don't catch and throw ourselves
            throw NetworkError.unknownError(error)
        }
    }
    
    enum HTTPMethodType {
        case get
        case post
        
        var rawValue: String {
            switch self {
            case .get:
                "GET"
            case .post:
                "POST"
            }
        }
    }
}
