//
// ChatLayout
// ChatLayoutSettings.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// `ChatLayout` settings.
public struct ChatLayoutSettings {

    /// Estimated item size for `ChatLayout`. This value will be used as the initial size of the item and the final size
    /// will be calculated using `UICollectionViewCell.preferredLayoutAttributesFitting(...)`.
    public var estimatedItemSize: CGSize?

    /// Spacing between the items in the section.
    public var interItemSpacing: CGFloat = 0

    /// Spacing between the sections.
    public var interSectionSpacing: CGFloat = 0

    /// Additional insets for the `ChatLayout` content.
    public var additionalInsets: UIEdgeInsets = .zero

}
