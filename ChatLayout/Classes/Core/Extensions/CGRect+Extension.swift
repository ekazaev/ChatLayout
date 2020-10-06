//
// ChatLayout
// CGRect+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

extension CGRect {

    func equalRounded(to rect: CGRect) -> Bool {
        return abs(origin.x - rect.origin.x) <= 1 &&
            abs(origin.y - rect.origin.y) <= 1 &&
            abs(size.width - rect.size.width) <= 1 &&
            abs(size.height - rect.size.height) <= 1
    }

    var higherPoint: CGPoint {
        return origin
    }

    var lowerPoint: CGPoint {
        return CGPoint(x: origin.x + size.width, y: origin.y + size.height)
    }

}
