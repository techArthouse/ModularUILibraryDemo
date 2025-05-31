//
//  UIDemoApp.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 2/26/24.
//

import SwiftUI
import ModularUILibrary

@main
struct UIDemoApp: App {
    let themeManager: ThemeManager = ThemeManager(imageAssetBundle: .main)
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}
