//
//  Constants.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import Foundation
// MARK: - global constants

//struct Constants {
//    enum imageSize: CGFloat {
//        case small = 24.0
//        case medium = 48.0
//        case large = 72.0
//    }
//    
//    enum TypeOfElement: String {
//        case imageContainer
//        case featureItemLeading
//        case rootBackground
//        
//        var debuggingColor: Color {
//            switch self {
//            case .imageContainer:
//                return .blue
//            case .featureItemLeading:
//                return .red
//            case .rootBackground:
//                return .black.opacity(0.5)
//            }
//        }
//    }
//    
//    static func highlightViewFrame(for elementType: TypeOfElement) -> Color {
//        elementType.debuggingColor
//    }
//}

// MARK: - Recipes Data Models

struct RecipeList: Decodable {
  let recipes: [Recipe]
}

struct Recipe: Decodable, Identifiable, Hashable {
    let id: UUID
    let cuisine: String
    let name: String
    
    // these reflect exactly what might be in—or missing from—the JSON
    private let photoUrlSmall: String?
    private let photoUrlLarge: String?
    private let sourceUrl:     String?
    private let youtubeUrl:    String?
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case cuisine, name, uuid
        case photoUrlSmall = "photo_url_small"
        case photoUrlLarge = "photo_url_large"
        case sourceUrl     = "source_url"
        case youtubeUrl    = "youtube_url"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cuisine = try c.decode(String.self, forKey: .cuisine)
        name = try c.decode(String.self, forKey: .name)
        
        // This can't be empty or malformed so we catch if it is.
        let uuidString = try c.decode(String.self, forKey: .uuid)
        guard let uuid = UUID(uuidString: uuidString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .uuid,
                in: c,
                debugDescription: "Invalid UUID string: \(uuidString)"
            )
        }
        id = uuid
        
        // These CAN be missing so we reflect that in data model
        photoUrlSmall = try c.decodeIfPresent(String.self, forKey: .photoUrlSmall)
        photoUrlLarge = try c.decodeIfPresent(String.self, forKey: .photoUrlLarge)
        sourceUrl     = try c.decodeIfPresent(String.self, forKey: .sourceUrl)
        youtubeUrl    = try c.decodeIfPresent(String.self, forKey: .youtubeUrl)
    }
}

extension Recipe {
    var uuidString: String {
        id.uuidString // gets id from source so one source of truth.
    }
    
    enum TestCase: String {
        case good = "recipesGood"
        case malformed = "recipesMalformed"
        case empty = "recipesEmpty"
        
        var jsonFileName: String {
            self.rawValue
        }
    }
    
    /// Load all recipes from the bundled recipes.json
    static func allFromJSON(using testCase: TestCase) async -> [Recipe] {
        do {
            let url = Bundle.main.url(
                forResource: testCase.jsonFileName,
                withExtension: "json"
            )!
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode(RecipeList.self, from: data)
            return list.recipes
        } catch {
            assertionFailure("🔴 Failed to load \(testCase.jsonFileName).json: \(error)")
            return []
        }
    }
    
    static func recipePreview(using testCase: TestCase) -> Recipe? {
        do {
            let url = Bundle.main.url(
                forResource: testCase.jsonFileName,
                withExtension: "json"
            )!
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode(RecipeList.self, from: data)
            return list.recipes.first
        } catch {
            assertionFailure("🔴 Failed to load \(testCase.jsonFileName).json: \(error)")
            return nil
        }
    }
}

/// Convenience props for URLS that return URL if it exists.
extension Recipe {
    var smallImageURL: URL? {
        guard let s = photoUrlSmall else { return nil }
        return URL(string: s)
    }
    
    var largeImageURL: URL? {
        guard let s = photoUrlLarge else { return nil }
        return URL(string: s)
    }
    
    var sourceWebsiteURL: URL? {
        guard let s = sourceUrl else { return nil }
        return URL(string: s)
    }
    
    var youtubeVideoURL: URL? {
        guard let s = youtubeUrl else { return nil }
        return URL(string: s)
    }
}

extension DynamicTypeSize {
    typealias size = ImageSize
    var photoDimension: CGFloat {
        switch self {
        case .xSmall, .small:
            size.small.size
        case .medium, .large, .xLarge:
            size.medium.size
        case .xxLarge, .xxxLarge, .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            size.large.size
        @unknown default:
            fatalError()
        }
    }
}

public enum ImageSize: Identifiable {
    public var id: CGFloat {
        self.rawValue
    }
    
    case small
    case medium
    case large
    case custom(CGFloat)
    
    public var size: CGFloat {
        switch self {
        case .small:
            return 24.0
        case .medium:
            return 48.0
        case .large:
            return 72.0
        case .custom(let value):
            return value
        }
    }
    
    var nextSize: ImageSize {
        switch self {
        case .small:
            return .medium
        case .medium:
            return .large
        case .large:
            return .small
        case .custom: // if we cycle from custom we go to defaults.
            return .medium
        }
    }
    
//        var rawValue: String {
//            switch self {
//            case .small:
//                return ".medium"
//            case .medium:
//                return "large"
//            case .large:
//                return "small"
//            case .custom: // if we cycle from custom we go to defaults.
//                return "medium"
//            }
//        }
}
extension ImageSize: RawRepresentable {
    public typealias RawValue = CGFloat
    
    /// Checks we have a acceptable value within default range 1 - 100.// This checks we have a acceptable value within default range 1 - 100.
    public init?(rawValue: CGFloat) {
        guard rawValue.isLessThanOrEqualTo(100), !rawValue.isLessThanOrEqualTo(0) else { return nil }
        self = .custom(rawValue)
    }

    public var rawValue: RawValue { return self.size }
}
