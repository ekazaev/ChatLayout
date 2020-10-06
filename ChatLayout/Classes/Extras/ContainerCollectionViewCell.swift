//
// ChatLayout
// ContainerCollectionViewCell.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
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
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `ChatLayout`
    /// - Returns: Modified `ChatLayoutAttributes` on nil if `UICollectionReusableView.preferredLayoutAttributesFitting(...)`
    ///            should be called instead.
    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes?

    /// Allows to additionally modify `ChatLayoutAttributes` after the `UICollectionReusableView.preferredLayoutAttributesFitting(...)`
    /// call.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `ChatLayout`.
    /// - Returns: Modified `ChatLayoutAttributes`
    func modifyPreferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes)

    /// Apply the specified layout attributes to the view.
    /// Keep in mind that this method can be called multiple times.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `ChatLayout`.
    func apply(_ layoutAttributes: ChatLayoutAttributes)

}

/// Default extension to make the methods optional for implementation in the successor
public extension ContainerCollectionViewCellDelegate {

    func prepareForReuse() {}

    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes? {
        return nil
    }

    func modifyPreferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) {}

    func apply(_ layoutAttributes: ChatLayoutAttributes) {}

}

/// A container `UICollectionViewCell` that constraints its contained view to its margins.
public final class ContainerCollectionViewCell<CustomView: UIView>: UICollectionViewCell {

    /// Default reuse identifier is set with the class name.
    public static var reuseIdentifier: String {
        return String(describing: self)
    }

    /// Contained view.
    public lazy var customView = CustomView(frame: bounds)

    /// An instance of `ContainerCollectionViewCellDelegate`
    public weak var delegate: ContainerCollectionViewCellDelegate?

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable, message: "Use init(reuseIdentifier:) instead")
    /// This constructor is unavailable.
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Performs any clean up necessary to prepare the view for use again.
    public override func prepareForReuse() {
        super.prepareForReuse()
        delegate?.prepareForReuse()
    }

    /// Gives the cell a chance to modify the attributes provided by the layout object.
    /// - Parameter layoutAttributes: The attributes provided by the layout object. These attributes represent the values that the layout intends to apply to the cell.
    /// - Returns: Modified `UICollectionViewLayoutAttributes`
    public override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }
        delegate?.apply(chatLayoutAttributes)
        let resultingLayoutAttributes: ChatLayoutAttributes
        if let preferredLayoutAttributes = delegate?.preferredLayoutAttributesFitting(chatLayoutAttributes) {
            resultingLayoutAttributes = preferredLayoutAttributes
        } else if let chatLayoutAttributes = super.preferredLayoutAttributesFitting(chatLayoutAttributes) as? ChatLayoutAttributes {
            delegate?.modifyPreferredLayoutAttributesFitting(chatLayoutAttributes)
            resultingLayoutAttributes = chatLayoutAttributes
        } else {
            resultingLayoutAttributes = chatLayoutAttributes
        }
        return resultingLayoutAttributes
    }

    /// Applies the specified layout attributes to the view.
    /// - Parameter layoutAttributes: The layout attributes to apply.
    public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
            return
        }
        super.apply(layoutAttributes)
        delegate?.apply(chatLayoutAttributes)
    }

    private func setupSubviews() {
        contentView.addSubview(customView)
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        contentView.insetsLayoutMarginsFromSafeArea = false
        contentView.layoutMargins = .zero

        customView.translatesAutoresizingMaskIntoConstraints = false
        customView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        customView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        customView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        customView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
    }

}
