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

protocol CanBeInvalid {
    var isInvalid: Bool { get }
}

struct RecipeList: Decodable {
    let recipes: [Recipe]
    let invalidRecipes: [Recipe]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let recipes = try? container.decode([Recipe].self, forKey: .recipes) else {
            throw RecipeDecodeError.unexpectedErrorWithDataModel("Could not fine `recipes` in root structure.")
        }
        var invalidRecipes = [Recipe]()
        var validRecipes = [Recipe]()
        
        for recipe in recipes {
            if recipe.isInvalid {
                invalidRecipes.append(recipe)
            } else {
                validRecipes.append(recipe)
            }
        }
        
        self.recipes = validRecipes
        self.invalidRecipes = invalidRecipes
    }
    
    enum CodingKeys: String, CodingKey {
        case recipes
    }
}

struct Recipe: Decodable, Identifiable, Hashable, CanBeInvalid {
    var isInvalid: Bool {
        _id == nil || _cuisine == nil || _name == nil
    }
    
    // Required Fields. Note that they take their value from underlying assumptions that these are required.
    var id: UUID { _id ?? UUID() }
    var cuisine: String { _cuisine ?? "N/A" }
    var name: String { _name ?? "N/A" }
    
    // Underlying required vars. We allow for the data model to not fail and still provide feedback on what failed.
    let _id: UUID?
    let _cuisine: String?
    let _name: String?
    let _uuidString: String? // The response model may have malformed uuid still.
    
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
        
        self._cuisine = try? c.decode(String.self, forKey: .cuisine)
        self._name = try? c.decode(String.self, forKey: .name)
        self._uuidString = try? c.decode(String.self, forKey: .uuid)
        if let uuidString = self._uuidString {
            self._id = UUID(uuidString: uuidString)
        } else {
            self._id = nil
        }
        
        // Optional
        photoUrlSmall = try? c.decodeIfPresent(String.self, forKey: .photoUrlSmall)
        photoUrlLarge = try? c.decodeIfPresent(String.self, forKey: .photoUrlLarge)
        sourceUrl     = try? c.decodeIfPresent(String.self, forKey: .sourceUrl)
        youtubeUrl    = try? c.decodeIfPresent(String.self, forKey: .youtubeUrl)
    }
}

extension Recipe {
    
    enum TestCase: String {
        case good = "recipesGood"
        case malformed = "recipesMalformed"
        case empty = "recipesEmpty"
        
        var jsonFileName: String {
            self.rawValue
        }
    }
    
    static func allFromJSON(using testCase: TestCase) async throws(RecipeDecodeError) -> [Recipe] {
        guard let url = Bundle.main.url(forResource: testCase.jsonFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw RecipeDecodeError.dataURLError
        }
        
        do {
            let list = try JSONDecoder().decode(RecipeList.self, from: data)
            
            return list.recipes + list.invalidRecipes
        } catch {
            throw RecipeDecodeError.unexpectedErrorWithDataModel("")
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
        } catch let error as RecipeDecodeError {
            return nil
        }
        catch {
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
