//
// ChatLayout
// MessageContainerView.swift
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

/// A container view that helps to layout the message view and its accessory

public final class MessageContainerView<AccessoryViewFactory: StaticViewFactory, MainView: NSUIView>: NSUIView {
    private lazy var stackView = NSUIStackView(frame: bounds)


    /// An accessory view.
    public lazy var accessoryView: AccessoryViewFactory.View? = AccessoryViewFactory.buildView(within: bounds)

    /// Main view.
    public var customView: MainView {
        internalContentView.customView
    }

    /// An alignment of the contained views within the `MessageContainerView`,
    public var alignment: ChatItemAlignment = .fullWidth {
        didSet {
            switch alignment {
            case .leading:
                internalContentView.flexibleEdges = [.trailing]
            case .trailing:
                internalContentView.flexibleEdges = [.leading]
            case .center:
                internalContentView.flexibleEdges = [.leading, .trailing]
            case .fullWidth:
                internalContentView.flexibleEdges = []
            }
        }
    }

    private lazy var internalContentView = EdgeAligningView<MainView>(frame: bounds)

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
        translatesAutoresizingMaskIntoConstraints = false
        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        #endif
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        stackView.orientation = .horizontal
        #endif

        #if canImport(UIKit)
        stackView.axis = .horizontal
        #endif
        stackView.spacing = .zero

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])

        if let accessoryView {
            stackView.addArrangedSubview(accessoryView)
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
        }

        internalContentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(internalContentView)
    }
}
