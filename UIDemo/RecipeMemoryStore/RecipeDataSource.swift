//
//  RecipeDataSource.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

@MainActor
final class RecipeDataSource: ObservableObject {
    private(set) var memories: [UUID: RecipeMemory] = [:]
    private let key = "RecipeMemories"

    static let shared = RecipeDataSource()
    
    private init() {
        load()
    }

    // MARK: – Public API

    func addNote(_ text: String, for recipeUUID: UUID) {
        guard var mem = memories[recipeUUID], mem.isFavorite else { return }
        let note = RecipeNote(id: UUID(), text: text, date: Date())
        mem.notes.append(note)
        memories[recipeUUID] = mem
        save()
    }

    func getMemory(for recipeUUID: UUID) -> RecipeMemory {
        if let res = memories[recipeUUID] {
            return res
        } else {
            return RecipeMemory(isFavorite: false, notes: [])
        }
    }

    // MARK: – Persistence

    private func load() {
        guard
          let data = UserDefaults.standard.data(forKey: key),
          let decoded = try? JSONDecoder().decode([UUID: RecipeMemory].self, from: data)
        else { return }
        memories = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // Explicitly set value for favorite
    func setFavorite(_ favorite: Bool, for recipeUUID: UUID) {
        if var mem = memories[recipeUUID] {
            mem.isFavorite = favorite
            memories[recipeUUID] = mem
        } else if favorite {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
        save()
    }
}

struct RecipeNote: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date
}

class RecipeMemory: Codable, ObservableObject {
    var isFavorite: Bool
    var notes: [RecipeNote]
    
    init(isFavorite: Bool, notes: [RecipeNote]) {
        self.isFavorite = isFavorite
        self.notes = notes
    }
}

extension RecipeDataSource: RecipeMemoryStoreProtocol {
    func isFavorite(for recipeUUID: UUID) -> Bool {
        getMemory(for: recipeUUID).isFavorite
    }

    func notes(for recipeUUID: UUID) -> [RecipeNote] {
        getMemory(for: recipeUUID).notes
    }
    
    func toggleFavorite(recipeUUID: UUID) {
        if var mem = memories[recipeUUID] {
            mem.isFavorite.toggle()
            // if unfavoriting, you might choose to drop notes
            // mem.notes.removeAll()
            memories[recipeUUID] = mem
        } else {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
        save()
    }
}
