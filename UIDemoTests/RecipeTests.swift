//
//  RecipeTests.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/14/25.
//

import XCTest
@testable import UIDemo

final class RecipeTests: XCTestCase {
    func test_debug_initializer_setsPropertiesAndNotInvalid() {
        let id = UUID()
        let recipe = Recipe(id: id, name: "TestName", cuisine: "TestCuisine")

        XCTAssertEqual(recipe.id, id)
        XCTAssertEqual(recipe.name, "TestName")
        XCTAssertEqual(recipe.cuisine, "TestCuisine")
        XCTAssertFalse(recipe.isNotValid)

        // URLs should be nil
        XCTAssertNil(recipe.smallImageURL)
        XCTAssertNil(recipe.largeImageURL)
        XCTAssertNil(recipe.sourceWebsiteURL)
        XCTAssertNil(recipe.youtubeVideoURL)
    }
    
    func test_decodingValidJSON_yieldsCorrectProperties() throws {
        let uuidString = UUID().uuidString
        let json = """
        {
          "uuid": "\(uuidString)",
          "name": "ValidName",
          "cuisine": "ValidCuisine",
          "photo_url_small": "https://example.com/small.jpg",
          "photo_url_large": "https://example.com/large.jpg",
          "source_url": "https://example.com",
          "youtube_url": "https://youtu.be/123"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        let recipe = try decoder.decode(Recipe.self, from: data)

        XCTAssertEqual(recipe.id.uuidString, uuidString)
        XCTAssertEqual(recipe.name, "ValidName")
        XCTAssertEqual(recipe.cuisine, "ValidCuisine")
        XCTAssertFalse(recipe.isNotValid)
        XCTAssertEqual(recipe.smallImageURL?.absoluteString, "https://example.com/small.jpg")
        XCTAssertEqual(recipe.largeImageURL?.absoluteString, "https://example.com/large.jpg")
        XCTAssertEqual(recipe.sourceWebsiteURL?.absoluteString, "https://example.com")
        XCTAssertEqual(recipe.youtubeVideoURL?.absoluteString, "https://youtu.be/123")
    }
    
    func test_decodingMissingRequiredFields_setsDefaultsAndInvalid() throws {
        let json = "{ }"
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        let recipe = try decoder.decode(Recipe.self, from: data)

        // No underlying values -> invalid
        XCTAssertTrue(recipe.isNotValid)
        XCTAssertEqual(recipe.name, "N/A")
        XCTAssertEqual(recipe.cuisine, "N/A")
    }
    
    /// For the following tests we give a default value if any of the required fields are missing or empty. 
    
    func test_decodingMalformedUUID_marksInvalidButSetsNameCuisine() throws {
        let json = """
        { "uuid": "not-a-uuid", "name": "A", "cuisine": "B" }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        let recipe = try decoder.decode(Recipe.self, from: data)

        // Malformed uuid -> invalid but retains name & cuisine
        XCTAssertTrue(recipe.isNotValid)
        XCTAssertEqual(recipe.name, "A")
        XCTAssertEqual(recipe.cuisine, "B")
    }
    
    func test_decodingMalformedUUID_marksInvalidButSetsUUID() throws {
        let id = UUID()
        let json = """
        { "uuid": "\(id)", "name": "", "cuisine": "" }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        let recipe = try decoder.decode(Recipe.self, from: data)
        
        XCTAssertEqual(recipe.name, "N/A") // We give the N/A val for both if nil/empty
        XCTAssertEqual(recipe.cuisine, "N/A")
        XCTAssertEqual(recipe.id, id)
        XCTAssertTrue(recipe.isNotValid)
    }
}
