//
// ChatLayout
// HorizontalEdgePadding.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import CoreGraphics

public struct HorizontalEdgePadding {
    public let left: CGFloat
    public let right: CGFloat

    public static let zero = HorizontalEdgePadding(left: 0, right: 0)

    public init(left: CGFloat, right: CGFloat) {
        self.left = left
        self.right = right
    }
}
