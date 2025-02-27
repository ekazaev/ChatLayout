//
//  ContainerCollectionViewItem.swift
//  ChatLayout
//
//  Created by JH on 2024/1/11.
//  Copyright © 2024 Eugene Kazaev. All rights reserved.
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

/// A container `UICollectionViewCell` that constraints its contained view to its margins.
public final class ContainerCollectionViewItem<CustomView: NSView>: NSCollectionViewItem {
    /// Default reuse identifier is set with the class name.
    public static var reuseIdentifier: String {
        String(describing: self)
    }

    /// Contained view.
    public lazy var customView = CustomView()

    /// An instance of `ContainerCollectionViewCellDelegate`
    public weak var delegate: ContainerCollectionViewCellDelegate?

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    public override func loadView() {
        view = customView
    }

    @available(*, unavailable, message: "Use init(reuseIdentifier:) instead.")
    /// This constructor is unavailable.
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }

    /// Performs any clean up necessary to prepare the view for use again.
    public override func prepareForReuse() {
        super.prepareForReuse()
        delegate?.prepareForReuse()
    }

    /// Gives the cell a chance to modify the attributes provided by the layout object.
    /// - Parameter layoutAttributes: The attributes provided by the layout object. These attributes represent the values that the layout intends to apply to the cell.
    /// - Returns: Modified `UICollectionViewLayoutAttributes`
    public override func preferredLayoutAttributesFitting(_ layoutAttributes: NSUICollectionViewLayoutAttributes) -> NSUICollectionViewLayoutAttributes {
        guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }
        

        delegate?.apply(chatLayoutAttributes)
        let resultingLayoutAttributes: ChatLayoutAttributes
        if let preferredLayoutAttributes = delegate?.preferredLayoutAttributesFitting(chatLayoutAttributes) {
            resultingLayoutAttributes = preferredLayoutAttributes
        } else if let chatLayoutAttributes = super.preferredLayoutAttributesFitting(chatLayoutAttributes) as? ChatLayoutAttributes {
            delegate?.modifyPreferredLayoutAttributesFitting(chatLayoutAttributes)
//            view.layoutSubtreeIfNeeded()
//            chatLayoutAttributes.size = view.fittingSize
            resultingLayoutAttributes = chatLayoutAttributes
        } else {
            resultingLayoutAttributes = chatLayoutAttributes
        }
        return resultingLayoutAttributes
    }

    /// Applies the specified layout attributes to the view.
    /// - Parameter layoutAttributes: The layout attributes to apply.
    public override func apply(_ layoutAttributes: NSUICollectionViewLayoutAttributes) {
        guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
            return
        }
        super.apply(layoutAttributes)
        delegate?.apply(chatLayoutAttributes)
    }
}

#endif
