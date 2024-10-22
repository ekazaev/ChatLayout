//
// ChatLayout
// CGRect+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

extension CGRect {
    var higherPoint: CGPoint {
        origin
    }

    var lowerPoint: CGPoint {
        CGPoint(x: origin.x + size.width, y: origin.y + size.height)
    }

    var centerPoint: CGPoint {
        CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }

    @inline(__always)
    mutating func offsettingBy(dx: CGFloat, dy: CGFloat) {
        origin.x += dx
        origin.y += dy
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension CGRect {

    func inset(by edgeInsets: NSEdgeInsets) -> CGRect {
        var result = self
        result.origin.x += edgeInsets.left
        result.origin.y += edgeInsets.top
        result.size.width -= edgeInsets.left + edgeInsets.right
        result.size.height -= edgeInsets.top + edgeInsets.bottom
        return result
    }
}
#endif

