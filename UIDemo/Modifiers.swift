//
//  Modifiers.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/12/25.
//

import SwiftUI
import Foundation

extension Data {
    public var imageIfImageData: Image? {
        guard let uiImage = UIImage(data: self) else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }
}
