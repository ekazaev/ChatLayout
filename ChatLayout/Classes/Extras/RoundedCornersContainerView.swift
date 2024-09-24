//
// ChatLayout
// RoundedCornersContainerView.swift
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

/// A container view that keeps its `CustomView` masked with the corner radius provided.
public final class RoundedCornersContainerView<CustomView: View>: View {
    /// Corner radius. If not provided then the half of the current view height will be used.
    public var cornerRadius: CGFloat?

    /// Contained view.
    public lazy var customView = CustomView(frame: bounds)

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

    private func setupSubviews() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        setWantsLayer()
        customView.setWantsLayer()
        #endif
        addSubview(customView)
        translatesAutoresizingMaskIntoConstraints = false
        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        #endif

        customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
    }

    /// Lays out subviews.
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public override func layout() {
        super.layout()
        layer?.masksToBounds = false
        layer?.cornerRadius = cornerRadius ?? frame.height / 2
        clipsToBounds = true
    }
    #endif

    #if canImport(UIKit)
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = false
        layer.cornerRadius = cornerRadius ?? frame.height / 2
        clipsToBounds = true
    }
    #endif
}
