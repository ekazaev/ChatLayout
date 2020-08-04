//
// ChatLayout
// ChatLayoutAttributes.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// Custom implementation of `UICollectionViewLayoutAttributes`
public class ChatLayoutAttributes: UICollectionViewLayoutAttributes {

    /// Alignment of the current item. Can be changed within `UICollectionViewCell.preferredLayoutAttributesFitting(...)`
    public var alignment: ChatItemAlignment = .full

    /// `ChatLayout`s additional insets setup using `ChatLayoutSettings`. Added for convenience.
    public internal(set) var additionalInsets: UIEdgeInsets = .zero

    /// `UICollectionView`s frame size. Added for convenience.
    public internal(set) var viewSize: CGSize = .zero

    /// `UICollectionView`s adjusted content insets. Added for convenience.
    public internal(set) var adjustedContentInsets: UIEdgeInsets = .zero

    /// `ChatLayout`s visible bounds size excluding `adjustedContentInsets`. Added for convenience.
    public internal(set) var visibleBoundsSize: CGSize = .zero

    /// `ChatLayout`s visible bounds size excluding `adjustedContentInsets` and `additionalInsets`. Added for convenience.
    public internal(set) var layoutFrame: CGRect = .zero

    var id: UUID? // Debug purposes only

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

    /// Returns an exact copy of `ChatLayoutAttributes`
    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ChatLayoutAttributes
        copy.alignment = alignment
        copy.additionalInsets = additionalInsets
        copy.viewSize = viewSize
        copy.adjustedContentInsets = adjustedContentInsets
        copy.visibleBoundsSize = visibleBoundsSize
        copy.layoutFrame = layoutFrame
        copy.id = id
        return copy
    }

    /// Returns a Boolean value indicating whether two `ChatLayoutAttributes` are considered equal.
    public override func isEqual(_ object: Any?) -> Bool {
        return super.isEqual(object)
            && alignment == (object as? ChatLayoutAttributes)?.alignment
    }

    var kind: ItemKind {
        switch (representedElementCategory, representedElementKind) {
        case (.cell, nil):
            return .cell
        case (.supplementaryView, .some(UICollectionView.elementKindSectionHeader)):
            return .header
        case (.supplementaryView, .some(UICollectionView.elementKindSectionFooter)):
            return .footer
        default:
            fatalError("Unsupported element kind")
        }
    }

}
