//
//  Modifiers.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/12/25.
//

import SwiftUI
import Foundation

extension Data {
    /// Returns an `Image` View conversion of a data blob if the data evaluates to an Image.
    /// nil if not.
    public var imageIfImageData: Image? {
        guard let uiImage = UIImage(data: self) else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }
}
