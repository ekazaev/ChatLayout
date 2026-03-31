//
// ChatLayout
// ChatLayoutPositionSnapshot.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// Represents content offset position expressed by the specific item and it offset from the top or bottom edge.
public struct ChatLayoutPositionSnapshot: Hashable, Sendable {
    /// Represents the edge.
    public enum Edge: Hashable, Sendable {
        /// Top edge of the `UICollectionView`
        case top

        /// Bottom edge of the `UICollectionView`
        case bottom
    }

    /// Item's `IndexPath`
    public var indexPath: IndexPath

    /// The edge of the offset.
    public var edge: Edge

    /// The offset from the `edge`.
    public var offset: CGFloat

    /// Constructor
    /// - Parameters:
    ///   - indexPath: Item's `IndexPath`
    ///   - edge: The edge of the offset.
    ///   - offset: The offset from the `edge`.
    public init(
        indexPath: IndexPath,
        edge: Edge,
        offset: CGFloat = 0
    ) {
        self.indexPath = indexPath
        self.edge = edge
        self.offset = offset
    }
}
