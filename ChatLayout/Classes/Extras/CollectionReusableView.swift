//
//  NSCollectionReusableView.swift
//  ChatLayout
//
//  Created by JH on 2024/1/12.
//  Copyright © 2024 Eugene Kazaev. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public class CollectionReusableView: NSView, NSCollectionViewElement {
    public override func prepareForReuse() {}

    public func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {}

    public func willTransition(from oldLayout: NSCollectionViewLayout, to newLayout: NSCollectionViewLayout) {}

    public func didTransition(from oldLayout: NSCollectionViewLayout, to newLayout: NSCollectionViewLayout) {}

    public func preferredLayoutAttributesFitting(_ layoutAttributes: NSCollectionViewLayoutAttributes) -> NSCollectionViewLayoutAttributes {
        layoutAttributes
    }
}

#endif
