//
// ChatLayout
// ContainerCollectionReusableView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
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

// A container `UICollectionReusableView` that constraints its contained view to its margins.

public final class ContainerCollectionReusableView<CustomView: NSUIView>: CollectionReusableView {
    /// Default reuse identifier is set with the class name.
    public static var reuseIdentifier: String {
        String(describing: self)
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

    /// This constructor is unavailable.
    @available(*, unavailable, message: "Use init(frame:) instead")
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Performs any clean up necessary to prepare the view for use again.
    public override func prepareForReuse() {
        super.prepareForReuse()
        delegate?.prepareForReuse()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    func callPrivatePreferredLayoutAttributes(fittingAttributes: NSCollectionViewLayoutAttributes) -> NSCollectionViewLayoutAttributes {
        let selector = NSSelectorFromString("preferredLayoutAttributesFittingAttributes:")
        let method = class_getInstanceMethod(NSView.self, selector)
        typealias Function = @convention(c) (Any, Selector, NSCollectionViewLayoutAttributes) -> NSCollectionViewLayoutAttributes
        let implementation = method.flatMap { method_getImplementation($0) }
        let function = unsafeBitCast(implementation, to: Function.self)
        return function(self, selector, fittingAttributes)
    }

    /// Gives the cell a chance to modify the attributes provided by the layout object.
    /// - Parameter layoutAttributes: The attributes provided by the layout object. These attributes represent the values that the layout intends to apply to the cell.
    /// - Returns: Modified `UICollectionViewLayoutAttributes`
    public func preferredLayoutAttributesFitting(_ layoutAttributes: NSUICollectionViewLayoutAttributes) -> NSUICollectionViewLayoutAttributes {
        guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
            return callPrivatePreferredLayoutAttributes(fittingAttributes: layoutAttributes)
        }
        delegate?.apply(chatLayoutAttributes)

        let resultingLayoutAttributes: ChatLayoutAttributes
        if let preferredLayoutAttributes = delegate?.preferredLayoutAttributesFitting(chatLayoutAttributes) {
            resultingLayoutAttributes = preferredLayoutAttributes
        } else if let chatLayoutAttributes = callPrivatePreferredLayoutAttributes(fittingAttributes: chatLayoutAttributes) as? ChatLayoutAttributes {
            delegate?.modifyPreferredLayoutAttributesFitting(chatLayoutAttributes)
            resultingLayoutAttributes = chatLayoutAttributes
        } else {
            resultingLayoutAttributes = chatLayoutAttributes
        }
        return resultingLayoutAttributes
    }

    /// Applies the specified layout attributes to the view.
    /// - Parameter layoutAttributes: The layout attributes to apply.
    public func apply(_ layoutAttributes: NSUICollectionViewLayoutAttributes) {
        guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
            return
        }
        delegate?.apply(chatLayoutAttributes)
    }
    #endif

    #if canImport(UIKit)
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
    #endif

    private func setupSubviews() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        setWantsLayer()
        #endif
        addSubview(customView)

        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        #endif

        customView.translatesAutoresizingMaskIntoConstraints = false
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: topAnchor),
            customView.bottomAnchor.constraint(equalTo: bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        #endif

        #if canImport(UIKit)
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
        #endif
    }
}
