//
// ChatLayout
// ChatLayoutAttributes.swift
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

/// Custom implementation of `UICollectionViewLayoutAttributes`
public final class ChatLayoutAttributes: UICollectionViewLayoutAttributes {
    /// Alignment of the current item. Can be changed within `UICollectionViewCell.preferredLayoutAttributesFitting(...)`
    public nonisolated(unsafe) var alignment: ChatItemAlignment = .fullWidth

    /// Pinning behavour of the current item.
    public nonisolated(unsafe) var pinningType: ChatItemPinningType? = nil

    /// Inter item spacing. Can be changed within `UICollectionViewCell.preferredLayoutAttributesFitting(...)`
    public nonisolated(unsafe) var interItemSpacing: CGFloat = 0

    /// `CollectionViewChatLayout`s additional insets setup using `ChatLayoutSettings`. Added for convenience.
    public internal(set) var additionalInsets: UIEdgeInsets = .zero

    /// `UICollectionView`s frame size. Added for convenience.
    public internal(set) var viewSize: CGSize = .zero

    /// `UICollectionView`s adjusted content insets. Added for convenience.
    public internal(set) var adjustedContentInsets: UIEdgeInsets = .zero

    /// `CollectionViewChatLayout`s visible bounds size excluding `adjustedContentInsets`. Added for convenience.
    public internal(set) var visibleBoundsSize: CGSize = .zero

    /// `CollectionViewChatLayout`s visible bounds size excluding `adjustedContentInsets` and `additionalInsets`. Added for convenience.
    public internal(set) var layoutFrame: CGRect = .zero

    #if DEBUG
    var id: UUID?
    #endif

    convenience init(kind: ItemKind, indexPath: IndexPath = IndexPath(item: 0, section: 0)) {
        switch kind {
        case .cell:
            self.init(forCellWith: indexPath)
        case .header:
            self.init(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: indexPath)
        case .footer:
            self.init(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: indexPath)
        }
    }

    /// Returns an exact copy of `ChatLayoutAttributes`.
    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ChatLayoutAttributes
        copy.viewSize = viewSize
        copy.alignment = alignment
        copy.interItemSpacing = interItemSpacing
        copy.layoutFrame = layoutFrame
        copy.additionalInsets = additionalInsets
        copy.visibleBoundsSize = visibleBoundsSize
        copy.adjustedContentInsets = adjustedContentInsets
        copy.pinningType = pinningType
        #if DEBUG
        copy.id = id
        #endif
        return copy
    }

    /// Returns a Boolean value indicating whether two `ChatLayoutAttributes` are considered equal.
    public override func isEqual(_ object: Any?) -> Bool {
        let chatLayoutAttributes = (object as? ChatLayoutAttributes)
        return super.isEqual(object)
            && pinningType == chatLayoutAttributes?.pinningType
            && alignment == chatLayoutAttributes?.alignment
            && interItemSpacing == chatLayoutAttributes?.interItemSpacing
    }

    /// `ItemKind` represented by this attributes object.
    public var kind: ItemKind {
        switch (representedElementCategory, representedElementKind) {
        case (.cell, nil):
            .cell
        case (.supplementaryView, .some(UICollectionView.elementKindSectionHeader)):
            .header
        case (.supplementaryView, .some(UICollectionView.elementKindSectionFooter)):
            .footer
        default:
            preconditionFailure("Unsupported element kind.")
        }
    }

    func typedCopy() -> ChatLayoutAttributes {
        guard let typedCopy = copy() as? ChatLayoutAttributes else {
            fatalError("Internal inconsistency.")
        }
        return typedCopy
    }
}
