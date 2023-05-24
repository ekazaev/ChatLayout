//
// ChatLayout
// UILayoutPriority+Extension.swift
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

extension UILayoutPriority {
    static let almostRequired = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 1)
}
