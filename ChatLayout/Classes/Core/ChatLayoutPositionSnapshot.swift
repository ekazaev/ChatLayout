//
// ChatLayout
// ChatLayoutPositionSnapshot.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// Represents content offset position expressed by the specific item and it offset from the top or bottom edge.
public struct ChatLayoutPositionSnapshot {

    /// Represents the edge.
    public enum Edge {

        /// Top edge of the `UICollectionView`
        case top

        /// Bottom edge of the `UICollectionView`
        case bottom

    }

    /// Item's `IndexPath`
    public var indexPath: IndexPath

    /// Kind of item at the `indexPath`
    public var kind: ItemKind

    /// The edge of the offset.
    public var edge: Edge

    /// The offset from the `edge`.
    public var offset: CGFloat

    /// Constructor
    /// - Parameters:
    ///   - indexPath: Item's `IndexPath`
    ///   - edge: The edge of the offset.
    ///   - offset: The offset from the `edge`.
    ///   - kind: Kind of item at the `indexPath`
    public init(indexPath: IndexPath,
                kind: ItemKind,
                edge: Edge,
                offset: CGFloat = 0) {
        self.indexPath = indexPath
        self.edge = edge
        self.offset = offset
        self.kind = kind
    }

}
