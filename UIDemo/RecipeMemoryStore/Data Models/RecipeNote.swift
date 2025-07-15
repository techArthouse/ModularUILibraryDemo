//
//  RecipeNote.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/13/25.
//

import Foundation

struct RecipeNote: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date
}
