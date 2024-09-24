//
//  NSImageView+.swift
//  ChatLayout
//
//  Created by JH on 2024/9/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import AppKit
import CoreImage

extension NSImageView {
    
    
    
    var tintColor: NSColor? {
        set {
            contentTintColor = newValue
        }
        get {
            contentTintColor
        }
    }
}

extension NSImage {
    convenience init?(systemName: String) {
        self.init(systemSymbolName: systemName, accessibilityDescription: nil)
    }
}

extension NSCollectionViewLayoutAttributes {
    var transform: CGAffineTransform {
        set {
            setValue(NSValue, forKeyPath: #function)
        }
        get {
            (value(forKeyPath: #function) as? NSValue)?.caTransform3DValue ?? .identity
        }
    }
}
