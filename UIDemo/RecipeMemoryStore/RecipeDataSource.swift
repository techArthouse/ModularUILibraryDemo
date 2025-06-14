//
//  RecipeDataSource.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/13/25.
//

import SwiftUI

@MainActor
final class RecipeDataSource: ObservableObject {
    @Published var memories: [String:RecipeMemory] = [:]
    private let key = "RecipeMemories"

    static let shared = RecipeDataSource()
    
    private init() {
        load()
    }

    // MARK: – Public API

    func toggleFavorite(url: URL) {
        let id = url.absoluteString
        if var mem = memories[id] {
            mem.isFavorite.toggle()
            // if unfavoriting, you might choose to drop notes
            // mem.notes.removeAll()
            memories[id] = mem
        } else {
            memories[id] = RecipeMemory(isFavorite: true, notes: [])
        }
        save()
    }

    func addNote(_ text: String, for url: URL) {
        let id = url.absoluteString
        guard var mem = memories[id], mem.isFavorite else { return }
        let note = RecipeNote(id: UUID(), text: text, date: Date())
        mem.notes.append(note)
        memories[id] = mem
        save()
    }

    func getMemory(for url: URL) -> RecipeMemory {
        let id = url.absoluteString
        print("well what is it: \(memories[id])")
        if let res = memories[id] {
            return res
        } else {
            return RecipeMemory(isFavorite: false, notes: [])
        }
//        return memories[id] ?? RecipeMemory(isFavorite: false, notes: [])
    }

    // MARK: – Persistence

    private func load() {
        guard
          let data = UserDefaults.standard.data(forKey: key),
          let decoded = try? JSONDecoder().decode([String:RecipeMemory].self, from: data)
        else { return }
        memories = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // Explicitly set value for favorite
    func setFavorite(_ favorite: Bool, for url: URL) {
        let id = url.absoluteString
        if var mem = memories[id] {
          mem.isFavorite = favorite
          memories[id] = mem
        } else if favorite {
          memories[id] = RecipeMemory(isFavorite: true, notes: [])
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

//struct RecipeMemory: Codable {
//    var isFavorite: Bool
//    var notes: [RecipeNote]
//}
