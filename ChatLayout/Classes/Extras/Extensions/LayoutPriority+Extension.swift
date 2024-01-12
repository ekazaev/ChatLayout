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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

extension LayoutPriority {
    static let almostRequired = LayoutPriority(rawValue: LayoutPriority.required.rawValue - 1)
}
