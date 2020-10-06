//
// ChatLayout
// ImageMaskedView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// A transformation to apply to the `ImageMaskedView.maskingImage`
public enum ImageMaskedViewTransformation {

    /// Keep image as it is.
    case asIs

    /// Flip image vertically.
    case flippedVertically

}

/// A container view that masks its contained view with an image provided.
public final class ImageMaskedView<CustomView: UIView>: UIView {

    /// Contained view.
    public lazy var customView = CustomView(frame: bounds)

    /// An Image to be used as a mask for the `customView`.
    public var maskingImage: UIImage? {
        didSet {
            setupMask()
        }
    }

    /// A transformation to apply to the `maskingImage`.
    public var maskTransformation: ImageMaskedViewTransformation = .asIs {
        didSet {
            guard oldValue != maskTransformation else {
                return
            }
            updateMask()
        }
    }

    private lazy var imageView = UIImageView(frame: bounds)

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    /// Returns an object initialized from data in a given unarchiver.
    /// - Parameter coder: An unarchiver object.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        addSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false
        customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }

    private func setupMask() {
        guard let bubbleImage = maskingImage else {
            imageView.image = nil
            mask = nil
            return
        }

        imageView.image = bubbleImage
        mask = imageView
        updateMask()
    }

    private func updateMask() {
        UIView.performWithoutAnimation {
            let multiplier = effectiveUserInterfaceLayoutDirection == .leftToRight ? 1 : -1
            switch maskTransformation {
            case .flippedVertically:
                imageView.transform = CGAffineTransform(scaleX: CGFloat(multiplier * -1), y: 1)
            case .asIs:
                imageView.transform = CGAffineTransform(scaleX: CGFloat(multiplier * 1), y: 1)
            }
        }
    }

    /// The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
    public override final var frame: CGRect {
        didSet {
            imageView.frame = bounds
        }
    }

    /// The bounds rectangle, which describes the view’s location and size in its own coordinate system.
    public override final var bounds: CGRect {
        didSet {
            imageView.frame = bounds
        }
    }

}
