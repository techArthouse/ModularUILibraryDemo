//
//  Recipe.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/11/25.
//

import SwiftUI

struct Recipe: Decodable, Identifiable, Hashable, CanBeInvalid {
    var isNotValid: Bool {
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
        
        if let rawCuisine = try? c.decode(String.self, forKey: .cuisine)
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !rawCuisine.isEmpty {
            self._cuisine = rawCuisine
        } else {
            self._cuisine = nil
        }
        
        // Decode & normalize name
        if let rawName = try? c.decode(String.self, forKey: .name)
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !rawName.isEmpty {
            self._name = rawName
        } else {
            self._name = nil
        }
        
        // UUID handling unchanged
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
    
    static func recipePreview(using testCase: TestCase) -> [Recipe] {
        do {
            let url = Bundle.main.url(
                forResource: testCase.jsonFileName,
                withExtension: "json"
            )!
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode(RecipeList.self, from: data)
            return list.recipes
        } catch let error as RecipeDecodeError {
            return []
        }
        catch {
            assertionFailure("🔴 Failed to load \(testCase.jsonFileName).json: \(error)")
            return []
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

// MARK: - DEBUG Structures/Previews

#if DEBUG
extension Recipe {
    /// Test  initializer
    init(id: UUID, name: String?, cuisine: String?) {
        self._id            = id
        self._name          = name
        self._cuisine       = cuisine
        self._uuidString    = id.uuidString
        
        // optional fields:
        self.photoUrlSmall  = nil
        self.photoUrlLarge  = nil
        self.sourceUrl      = nil
        self.youtubeUrl     = nil
    }
}
#endif
