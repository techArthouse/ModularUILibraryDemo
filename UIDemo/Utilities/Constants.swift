//
//  Constants.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 5/30/25.
//

import SwiftUI
import Foundation
import ModularUILibrary

enum NetworkEndpoint: String {
    case root = "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json"
}
protocol CanBeInvalid {
    var isValid: Bool { get }
}

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

