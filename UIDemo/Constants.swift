//
//  Constants.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import Foundation
import ModularUILibrary
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
    // Required Fields
    let id: UUID
    let cuisine: String
    let name: String
    
    // Optional by API
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
        
        do {
            // Required
            cuisine = try c.decode(String.self, forKey: .cuisine)
            name = try c.decode(String.self, forKey: .name)
            let uuidString = try c.decode(String.self, forKey: .uuid)
            guard let uuid = UUID(uuidString: uuidString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .uuid,
                    in: c,
                    debugDescription: "Invalid UUID string: \(uuidString)"
                )
            }
            id = uuid
        } catch {
            print("Recipe Decode error for a required field: \(error)")
            throw RecipeDecodeError.requiredFieldMissingOrMalformed(error, [:])
        }
        
        // Optional
        photoUrlSmall = try? c.decodeIfPresent(String.self, forKey: .photoUrlSmall)
        photoUrlLarge = try? c.decodeIfPresent(String.self, forKey: .photoUrlLarge)
        sourceUrl     = try? c.decodeIfPresent(String.self, forKey: .sourceUrl)
        youtubeUrl    = try? c.decodeIfPresent(String.self, forKey: .youtubeUrl)
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
    
//    /// Load all recipes from the bundled recipes.json
//    static func allFromJSON(using testCase: TestCase) async -> [Recipe] {
//        do {
//            let url = Bundle.main.url(
//                forResource: testCase.jsonFileName,
//                withExtension: "json"
//            )!
//            let data = try Data(contentsOf: url)
//            let list = try JSONDecoder().decode(RecipeList.self, from: data)
//            return list.recipes
//        } catch {
//            assertionFailure("🔴 Failed to load \(testCase.jsonFileName).json: \(error)")
//            return []
//        }
//    }
    
    static func allFromJSON(using testCase: TestCase) async throws(RecipeDecodeError) -> [Recipe] {
        guard let url = Bundle.main.url(forResource: testCase.jsonFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw RecipeDecodeError.dataURLError
        }
        
        var recipeLoadResults = Self.parseRecipes(data)
        var validRecipes: [Recipe] = []
        var errorCount = 0
        print("Total number of asdfasdfasd")
        for result in recipeLoadResults {
            switch result {
            case .valid(let recipe):
                validRecipes.append(recipe)
            case .invalid(let recipeDecodeError):
                print(recipeDecodeError.localizedDescription)
                errorCount += 1
            }
        }
        
        if errorCount > 0 {
            print("Total number of errors decoding recipes: \(errorCount)")
        }
        print("Total number of \(recipeLoadResults.count)")
        return validRecipes
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

// MARK: - Serialization Helpers

/// These methods help decode the recipe list gracefully such as to show what we can instead of disgard the whole list.
/// We prioritize resilient architecture and user experience.
extension Recipe {
    enum RecipeLoadResult {
        case valid(Recipe)
        case invalid(RecipeDecodeError)
    }

    static func parseRecipes(_ data: Data) -> [RecipeLoadResult] {
        guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return rawArray.map { dict in
            guard JSONSerialization.isValidJSONObject(dict) else { // Check if each entry is valid serialized data
                return .invalid(.invalidJsonObject(dict))
            }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                let recipe = try JSONDecoder().decode(Recipe.self, from: jsonData)
                return .valid(recipe)
            } catch {
                return .invalid(.requiredFieldMissingOrMalformed(error, dict))
            }
        }
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

enum AssetIdentifier: CustomImageIdentifierProtocol {
    case speakerOff
    case collapseArrow
    
    
    var rawValue: String {
        switch self {
        case .speakerOff:
            "speakerOffIcon"
        case .collapseArrow:
            "collapseArrowIcon"
        }
    }
}

enum RecipeDecodeError: LocalizedError {
    case requiredFieldMissingOrMalformed(Error, [String: Any])
    case invalidJsonObject([String: Any])
    case dataURLError
    
    var errorDescription: String? {
        switch self {
        case .requiredFieldMissingOrMalformed(let e, let dict):
            return "Required data field is missing or malformed. Error: \(e.localizedDescription) for \(dict.debugDescription)"
        case .invalidJsonObject(let dict):
            return "JsonSerialization error for invalid json object: \(dict.debugDescription)"
        case .dataURLError:
            return "Error occured attempting to form data url."
        }
    }
}

public enum CustomFont: String {
    case RobotoMono
    
    func regular(size: CGFloat = 16) -> Font { //}: ((_ size: CGFloat? ) -> Font) {
        switch self {
        case .RobotoMono:
            return Font.custom("RobotoMono-Regular", size: size)
            
        }
    }
    
    func light(size: CGFloat = 16) -> Font {
        switch self {
        case .RobotoMono:
                .custom("RobotoMono-Light", size: size)
        }
    }
}

public extension Font {
    static var robotoMono: CustomFont {
        CustomFont.RobotoMono
    }
}
