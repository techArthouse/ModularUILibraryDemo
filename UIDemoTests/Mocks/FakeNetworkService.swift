//
//  FakeNetworkService.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/17/25.
//

import Foundation
@testable import UIDemo

final class FakeNetworkService: NetworkServiceProtocol {
    var shouldThrow = false
    var fakeData: Data?

    func requestData(from url: URL, using method: NetworkService.HTTPMethodType = .get) async throws(NetworkError) -> Data {
        if shouldThrow {
            throw NetworkError.statusCodeFailure(500)
        }
        return fakeData ?? Data()
    }
}
