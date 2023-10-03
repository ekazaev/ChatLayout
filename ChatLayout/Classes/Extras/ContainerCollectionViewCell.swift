//
// ChatLayout
// ContainerCollectionViewCell.swift
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

/// A container `UICollectionViewCell` that constraints its contained view to its margins.
public final class ContainerCollectionViewCell<CustomView: UIView>: UICollectionViewCell {

    public override var frame: CGRect {
        get {
            super.frame
        }
        set {
            let oldValue = super.frame
            if newValue != super.frame {
                print("Frame changed: \(super.frame) -> \(newValue)")
            }
            super.frame = newValue
        }
    }

    public override var bounds: CGRect {
        get {
            super.bounds
        }
        set {
            let oldValue = super.bounds
            if newValue != super.bounds {
                print("Bounds changed: \(super.bounds) -> \(newValue)")
            }
            super.bounds = newValue
        }
    }

    public override var center: CGPoint {
        get {
            super.center
        }
        set {
            let oldValue = super.center
            if newValue != super.center {
                print("Center changed: \(super.center) -> \(newValue)")
            }
            super.center = newValue
        }
    }

    public override var isHidden: Bool {
        get {
            super.isHidden
        }
        set {
            let oldValue = super.isHidden
            if newValue != super.isHidden {
                print("isHidden changed: \(super.isHidden) -> \(newValue)")
            }
            super.isHidden = newValue
        }
    }

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
    public override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }
        delegate?.apply(chatLayoutAttributes)
        let resultingLayoutAttributes: ChatLayoutAttributes
        layoutAttributes.size = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        print("\(Self.self) \(#function) \(layoutAttributes.indexPath) \(frame.size) \(layoutAttributes.size)")
        resultingLayoutAttributes = layoutAttributes as! ChatLayoutAttributes
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
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        contentView.insetsLayoutMarginsFromSafeArea = false
        contentView.layoutMargins = .zero

        customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            customView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }

}
