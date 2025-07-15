//
//  RecipeDataSource.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

@MainActor
final class RecipeMemoryDataSource: RecipeMemoryDataSourceProtocol {
    private let defaults: UserDefaults
    private let key: String
    
    @Published private(set) var memories: [UUID: RecipeMemory] = [:]
    
    /// The key for memory stored.
    init(key: String = "RecipeMemories", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
        load()
    }

    // MARK: – Persistence

    internal func load() {
        guard
          let data = defaults.data(forKey: key),
          let decoded = try? JSONDecoder().decode([UUID: RecipeMemory].self, from: data)
        else { return }
        memories = decoded
    }

    internal func save() {
        if let data = try? JSONEncoder().encode(memories) {
            defaults.set(data, forKey: key)
        }
    }
    
    // MARK: – Public API

    func getMemory(for recipeUUID: UUID) -> RecipeMemory {
        if let res = memories[recipeUUID] {
            return res
        } else {
            return RecipeMemory(isFavorite: false, notes: [])
        }
    }
    
    func isFavorite(for recipeUUID: UUID) -> Bool {
        getMemory(for: recipeUUID).isFavorite
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
    
    func toggleFavorite(recipeUUID: UUID) {
        if var mem = memories[recipeUUID] {
            mem.isFavorite.toggle()
            // if unfavoriting, should we delete notes?
            // mem.notes.removeAll()
            memories[recipeUUID] = mem
        } else {
            memories[recipeUUID] = RecipeMemory(isFavorite: true, notes: [])
        }
        save()
    }
    
    func notes(for recipeUUID: UUID) -> [RecipeNote] {
        getMemory(for: recipeUUID).notes
    }
    
    func addNote(_ text: String, for recipeUUID: UUID) {
        guard var mem = memories[recipeUUID], mem.isFavorite else {
            return
        }
        
        let note = RecipeNote(id: UUID(), text: text, date: Date())
        mem.notes.append(note)
        memories[recipeUUID] = mem
        save()
    }
    
    func deleteNotes(for recipeUUID: UUID) {
        if var mem = memories[recipeUUID] {
            mem.notes.removeAll()
            memories[recipeUUID] = mem
            save()
        }
    }
}
