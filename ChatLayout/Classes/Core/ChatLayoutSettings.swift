//
// ChatLayout
// ChatLayoutSettings.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// `CollectionViewChatLayout` settings.
public struct ChatLayoutSettings: Equatable {
    /// Represents type of pinnable elements in the layout.
    public enum PinneableItems: Equatable {
        /// Pin supplementary views (header and/or footer).
        case supplementaryViews
        /// Pin cells
        case cells
    }

    /// Estimated item size for `CollectionViewChatLayout`. This value will be used as the initial size of the item and the final size
    /// will be calculated using `UICollectionViewCell.preferredLayoutAttributesFitting(...)`.
    public var estimatedItemSize: CGSize?

    /// Spacing between the items in the section.
    public var interItemSpacing: CGFloat = 0

    /// Spacing between the sections.
    public var interSectionSpacing: CGFloat = 0

    /// Additional insets for the `CollectionViewChatLayout` content.
    public var additionalInsets: UIEdgeInsets = .zero

    /// Confugures what elements can be pinned in the layout.
    public var pinnableItems: PinneableItems = .supplementaryViews
}
