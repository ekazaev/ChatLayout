//
// ChatLayout
// ImageMaskedView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
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

/// A transformation to apply to the `ImageMaskedView.maskingImage`
public enum ImageMaskedViewTransformation {
    /// Keep image as it is.
    case asIs

    /// Flip image vertically.
    case flippedVertically
}

/// A container view that masks its contained view with an image provided.
public final class ImageMaskedView<CustomView: NSUIView>: NSUIView {
    /// Contained view.
    public lazy var customView = CustomView(frame: bounds)

    /// An Image to be used as a mask for the `customView`.
    public var maskingImage: NSUIImage? {
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

    private lazy var imageView = NSUIImageView(frame: bounds)

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    /// Returns an object initialized from data in a given unarchiver.
    /// - Parameter coder: An unarchiver object.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public override var isFlipped: Bool { true }
    #endif

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        setWantsLayer()
        imageView.setWantsLayer()
        #endif
        #if canImport(UIKit)
        layoutMargins = .zero
        insetsLayoutMarginsFromSafeArea = false
        #endif

        addSubview(customView)
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

    private func setupMask() {
        guard let bubbleImage = maskingImage else {
            imageView.image = nil
            platformLayer?.mask = nil
            return
        }

        imageView.image = bubbleImage
        platformLayer?.mask = imageView.platformLayer
        updateMask()
    }

    private func updateMask() {
        NSUIView.performWithoutAnimation {
            let multiplier = effectiveUserInterfaceLayoutDirection == .leftToRight ? 1 : -1
            switch maskTransformation {
            case .flippedVertically:
                imageView.platformLayer?.setAffineTransform(CGAffineTransform(scaleX: CGFloat(multiplier * -1), y: 1))
            case .asIs:
                imageView.platformLayer?.setAffineTransform(CGAffineTransform(scaleX: CGFloat(multiplier * 1), y: 1))
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
