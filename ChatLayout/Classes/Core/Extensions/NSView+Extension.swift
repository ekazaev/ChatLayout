//
//  NSView+Extension.swift
//  ChatLayout
//
//  Created by JH on 2024/1/12.
//  Copyright © 2024 Eugene Kazaev. All rights reserved.
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSView {
    func layoutIfNeeded() {
        layoutSubtreeIfNeeded()
    }

    func setNeedsLayout() {
        needsLayout = true
    }
    
    func setNeedsDisplay() {
        needsDisplay = true
    }
    
    func setNeedsUpdateConstraints() {
        needsUpdateConstraints = true
    }
}

#endif
