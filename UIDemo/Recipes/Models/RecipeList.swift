//
//  RecipeList.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/11/25.
//

// Decodes response model for recipe list. Future proof: separates valid recipes from invalid recipes
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
            if recipe.isValid {
                validRecipes.append(recipe)
            } else {
                invalidRecipes.append(recipe)
            }
        }
        
        self.recipes = validRecipes
        self.invalidRecipes = invalidRecipes
    }
    
    enum CodingKeys: String, CodingKey {
        case recipes
    }
}
