//
// ChatLayout
// CGRect+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

extension CGRect {

    func equalRounded(to rect: CGRect) -> Bool {
        abs(origin.x - rect.origin.x) <= 1 &&
            abs(origin.y - rect.origin.y) <= 1 &&
            abs(size.width - rect.size.width) <= 1 &&
            abs(size.height - rect.size.height) <= 1
    }

    var higherPoint: CGPoint {
        origin
    }

    var lowerPoint: CGPoint {
        CGPoint(x: origin.x + size.width, y: origin.y + size.height)
    }

}
