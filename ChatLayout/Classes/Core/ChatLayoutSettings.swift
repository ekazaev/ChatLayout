//
// ChatLayout
// ChatLayoutSettings.swift
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

/// `CollectionViewChatLayout` settings.
public struct ChatLayoutSettings: Equatable, Sendable {
    /// Estimated item size for `CollectionViewChatLayout`. This value will be used as the initial size of the item and the final size
    /// will be calculated using `UICollectionViewCell.preferredLayoutAttributesFitting(...)`.
    public var estimatedItemSize: CGSize?

    /// Spacing between the items in the section.
    public var interItemSpacing: CGFloat = 0

    /// Spacing between the sections.
    public var interSectionSpacing: CGFloat = 0

    /// Additional insets for the `CollectionViewChatLayout` content.
    public var additionalInsets: UIEdgeInsets = .zero

    /// When set to a valid cell index path, `CollectionViewChatLayout` reports additional vertical content size
    /// so that the specified cell can scroll all the way to the top edge of the layout viewport.
    public var indexPathForExtendedLayout: IndexPath?
}
