//
//  Tab.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/18/25.
//




import SwiftUI
import ModularUILibrary

// MARK: - Navigation State

enum Tab: Hashable {
    case home, favorites, profile
}

enum Route: Hashable {
    case recipes
    case recipeDetail(UUID)
}