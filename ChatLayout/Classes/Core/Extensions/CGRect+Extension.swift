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

    // Had to introduce this comparision as the numbers slightly changes on the actual device.
    func equalRounded(to rect: CGRect) -> Bool {
        return origin.x.rounded() == rect.origin.x.rounded() &&
            origin.y.rounded() == rect.origin.y.rounded() &&
            size.width.rounded() == rect.size.width.rounded() &&
            size.height.rounded() == rect.size.height.rounded()
    }

    var higherPoint: CGPoint {
        return origin
    }

    var lowerPoint: CGPoint {
        return CGPoint(x: origin.x + size.width, y: origin.y + size.height)
    }

}
