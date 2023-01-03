//
// ChatLayout
// ContainerCollectionViewCellDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2023.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// A delegate of `ContainerCollectionViewCell`/`ContainerCollectionReusableView` should implement this methods if
/// it is required to participate in containers lifecycle.
public protocol ContainerCollectionViewCellDelegate: AnyObject {

    /// Perform any clean up necessary to prepare the view for use again.
    func prepareForReuse()

    /// Allows to override the call of `ContainerCollectionViewCell`/`ContainerCollectionReusableView`
    /// `UICollectionReusableView.preferredLayoutAttributesFitting(...)` and make the layout calculations.
    ///
    /// **NB**: You must override it to avoid unnecessary autolayout calculations if you are providing exact cell size
    /// in `ChatLayoutDelegate.sizeForItem(...)` and return `layoutAttributes` without modifications.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `CollectionViewChatLayout`
    /// - Returns: Modified `ChatLayoutAttributes` on nil if `UICollectionReusableView.preferredLayoutAttributesFitting(...)`
    ///            should be called instead.
    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes?

    /// Allows to additionally modify `ChatLayoutAttributes` after the `UICollectionReusableView.preferredLayoutAttributesFitting(...)`
    /// call.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `CollectionViewChatLayout`.
    /// - Returns: Modified `ChatLayoutAttributes`
    func modifyPreferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes)

    /// Apply the specified layout attributes to the view.
    /// Keep in mind that this method can be called multiple times.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `CollectionViewChatLayout`.
    func apply(_ layoutAttributes: ChatLayoutAttributes)

}

/// Default extension to make the methods optional for implementation in the successor
public extension ContainerCollectionViewCellDelegate {

    /// Default implementation does nothing.
    func prepareForReuse() {}

    /// Default implementation returns: `nil`.
    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes? {
        nil
    }

    /// Default implementation does nothing.
    func modifyPreferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) {}

    /// Default implementation does nothing.
    func apply(_ layoutAttributes: ChatLayoutAttributes) {}

}
