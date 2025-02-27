//
// ChatLayout
// Constants.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import CoreGraphics

struct Constants {
    static let tailSize: CGFloat = 5

    static let maxWidth: CGFloat = 0.65

    private init() {}
}
// It's advisable to continue using the reload/reconfigure method, especially when multiple changes occur concurrently in an animated fashion.
// This approach ensures that the ChatLayout can handle these changes while maintaining the content offset accurately.
// Consider using it when no better alternatives are available.
let enableSelfSizingSupport = false

// By setting this flag to true you can test reconfigure instead of reload.
let enableReconfigure = false
