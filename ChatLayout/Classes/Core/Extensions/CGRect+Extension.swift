//
// ChatLayout
// CGRect+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2023.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

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

    @inline(__always) mutating func offsettingBy(dx: CGFloat, dy: CGFloat) {
        origin.x += dx
        origin.y += dy
    }

}
