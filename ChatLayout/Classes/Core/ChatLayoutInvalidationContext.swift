//
// ChatLayout
// ChatLayoutInvalidationContext.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
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

/// Custom implementation of `UICollectionViewLayoutInvalidationContext`
public final class ChatLayoutInvalidationContext: CollectionViewLayoutInvalidationContext {

    /// Indicates whether to recompute the positions and sizes of the items based on the current
    /// collection view and delegate layout metrics.
    public var invalidateLayoutMetrics = true
}
