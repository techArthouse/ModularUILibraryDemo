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
    func requestData(from url: URL, using method: HTTPMethodType = .get ) async throws(NetworkError) -> Data {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            print("image network requested")
            try await Task.sleep(for: .seconds(3))
            
            let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if statusCodeSuccessRange.contains(httpResponse.statusCode) {
                    return data
                } else {
                    throw NetworkError.statusCodeFailure(httpResponse.statusCode)
                }
            } else {
                throw NetworkError.malformedHTTPResponse
            }
        } catch let e as NetworkError {
            throw e
        } catch let e as URLError {
            throw NetworkError.generalURLError(e)
        } catch {
            throw NetworkError.unkownError(error)
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
