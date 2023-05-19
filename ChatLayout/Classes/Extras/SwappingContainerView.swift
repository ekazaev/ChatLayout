//
// ChatLayout
// SwappingContainerView.swift
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

/// This container view is designed to hold two `UIView` elements and arrange them in a horizontal or vertical axis.
/// It also allows to easily change the order of the views if needed.
public final class SwappingContainerView<CustomView: UIView, AccessoryView: UIView>: UIView {

    /// Keys that specify a horizontal or vertical layout constraint between views.
    public enum Axis: Hashable {
        /// The constraint applied when laying out the horizontal relationship between views.
        case horizontal

        /// The constraint applied when laying out the vertical relationship between views.
        case vertical

    }

    /// Keys that specify a distribution of the contained views.
    public enum Distribution: Hashable {

        /// The `AccessoryView` should be positioned before the `CustomView`.
        case accessoryFirst

        /// The `AccessoryView` should be positioned after the `CustomView`.
        case accessoryLast

    }

    /// The layout of the arranged subviews along the axis.
    public var distribution: Distribution = .accessoryFirst {
        didSet {
            guard distribution != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }

    /// The distribution axis of the contained view.
    public var axis: Axis = .horizontal {
        didSet {
            guard axis != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }

    /// The distance in points between the edges of the contained views.
    public var spacing: CGFloat = 0 {
        didSet {
            guard spacing != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }

    /// Contained accessory view.
    public let accessoryView: AccessoryView

    /// Contained main view.
    public let customView: CustomView

    private struct SwappingContainerState: Equatable {
        let axis: Axis
        let position: Distribution
        let spacing: CGFloat
        let isAccessoryHidden: Bool
        let isCustomViewHidden: Bool
    }

    private lazy var accessoryFirstConstraints: [NSLayoutConstraint] = {
        [
            accessoryView.trailingAnchor.constraint(equalTo: customView.leadingAnchor, constant: spacing),
            accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ]
    }()

    private lazy var accessoryTopConstraints: [NSLayoutConstraint] = {
        [
            accessoryView.bottomAnchor.constraint(equalTo: customView.topAnchor, constant: -spacing),
            accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
    }()

    private lazy var accessoryFullConstraints: [NSLayoutConstraint] = {
        [
            accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ]
    }()

    private lazy var accessoryFullVConstraints: [NSLayoutConstraint] = {
        [
            accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
    }()

    private lazy var customViewFirstConstraints: [NSLayoutConstraint] = {
        [
            customView.trailingAnchor.constraint(equalTo: accessoryView.leadingAnchor, constant: -spacing),
            customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ]
    }()

    private lazy var customViewTopConstraints: [NSLayoutConstraint] = {
        [
            customView.bottomAnchor.constraint(equalTo: accessoryView.topAnchor, constant: -spacing),
            customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
    }()

    private lazy var customViewFullConstraints: [NSLayoutConstraint] = {
        [
            customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ]
    }()

    private lazy var customViewFullVConstraints: [NSLayoutConstraint] = {
        [
            customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
    }()

    private lazy var topBottomConstraints: (accessory: [NSLayoutConstraint], customView: [NSLayoutConstraint]) = {
        (accessory: [accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                     accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)],
         customView: [customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                      customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)])
    }()

    private lazy var leadingTrailingConstraints: (accessory: [NSLayoutConstraint], customView: [NSLayoutConstraint]) = {
        (accessory: [accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                     accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)],
         customView: [customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                      customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)])
    }()

    private var cachedState: SwappingContainerState?

    private var accessoryFirstObserver: NSKeyValueObservation?

    private var customViewObserver: NSKeyValueObservation?

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   - axis: The view distribution axis.
    ///   - distribution: The layout of the arranged subviews along the axis.
    ///   - spacing: The distance in points between the edges of the contained views.
    ///   to the superview in which you plan to add it.
    public init(frame: CGRect,
                axis: Axis = .horizontal,
                distribution: Distribution = .accessoryFirst,
                spacing: CGFloat) {
        customView = CustomView(frame: frame)
        accessoryView = AccessoryView(frame: frame)
        self.axis = axis
        self.distribution = distribution
        self.spacing = spacing
        super.init(frame: frame)
        setupSubviews()
    }

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    public override init(frame: CGRect) {
        customView = CustomView(frame: frame)
        accessoryView = AccessoryView(frame: frame)
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable, message: "Use init(frame:) instead.")
    /// This constructor is unavailable.
    public required init?(coder: NSCoder) {
        fatalError("Use init(with:flexibleEdges:) instead.")
    }

    /// Updates constraints for the view.
    public override func updateConstraints() {
        let currentState = SwappingContainerState(axis: axis,
                                                  position: distribution,
                                                  spacing: spacing,
                                                  isAccessoryHidden: accessoryView.isHidden,
                                                  isCustomViewHidden: customView.isHidden)
        guard currentState != cachedState else {
            super.updateConstraints()
            return
        }

        if let cachedState,
           cachedState.axis != axis {
            switch cachedState.axis {
            case .horizontal:
                NSLayoutConstraint.deactivate(topBottomConstraints.accessory)
                NSLayoutConstraint.deactivate(topBottomConstraints.customView)
                NSLayoutConstraint.deactivate(accessoryFirstConstraints)
                NSLayoutConstraint.deactivate(customViewFirstConstraints)
                NSLayoutConstraint.deactivate(accessoryFullConstraints)
                NSLayoutConstraint.deactivate(customViewFullConstraints)
            case .vertical:
                NSLayoutConstraint.deactivate(leadingTrailingConstraints.accessory)
                NSLayoutConstraint.deactivate(leadingTrailingConstraints.customView)
                NSLayoutConstraint.deactivate(accessoryTopConstraints)
                NSLayoutConstraint.deactivate(customViewTopConstraints)
                NSLayoutConstraint.deactivate(accessoryFullVConstraints)
                NSLayoutConstraint.deactivate(customViewFullVConstraints)
            }
        }

        cachedState = currentState

        switch axis {
        case .horizontal:
            if currentState.isAccessoryHidden, currentState.isCustomViewHidden {
                NSLayoutConstraint.deactivate(topBottomConstraints.accessory)
                NSLayoutConstraint.deactivate(topBottomConstraints.customView)
                NSLayoutConstraint.deactivate(accessoryFirstConstraints)
                NSLayoutConstraint.deactivate(customViewFirstConstraints)
                NSLayoutConstraint.deactivate(accessoryFullConstraints)
                NSLayoutConstraint.deactivate(customViewFullConstraints)
            } else if currentState.isAccessoryHidden {
                NSLayoutConstraint.deactivate(topBottomConstraints.accessory)
                NSLayoutConstraint.deactivate(accessoryFirstConstraints)
                NSLayoutConstraint.deactivate(customViewFirstConstraints)
                NSLayoutConstraint.deactivate(accessoryFullConstraints)
                NSLayoutConstraint.activate(customViewFullConstraints)
                NSLayoutConstraint.activate(topBottomConstraints.customView)
            } else if currentState.isCustomViewHidden {
                NSLayoutConstraint.deactivate(topBottomConstraints.customView)
                NSLayoutConstraint.deactivate(accessoryFirstConstraints)
                NSLayoutConstraint.deactivate(customViewFirstConstraints)
                NSLayoutConstraint.deactivate(customViewFullConstraints)
                NSLayoutConstraint.activate(accessoryFullConstraints)
                NSLayoutConstraint.activate(topBottomConstraints.accessory)
            } else {
                NSLayoutConstraint.deactivate(accessoryFullConstraints)
                NSLayoutConstraint.deactivate(customViewFullConstraints)

                switch distribution {
                case .accessoryFirst:
                    guard !(accessoryFirstConstraints.first?.isActive ?? false) else {
                        break
                    }
                    accessoryFirstConstraints.first?.constant = -spacing
                    customViewFirstConstraints.first?.constant = spacing
                    NSLayoutConstraint.deactivate(customViewFirstConstraints)
                    NSLayoutConstraint.activate(accessoryFirstConstraints)
                case .accessoryLast:
                    guard !(customViewFirstConstraints.first?.isActive ?? false) else {
                        break
                    }
                    accessoryFirstConstraints.first?.constant = spacing
                    customViewFirstConstraints.first?.constant = -spacing
                    NSLayoutConstraint.deactivate(accessoryFirstConstraints)
                    NSLayoutConstraint.activate(customViewFirstConstraints)
                }
                NSLayoutConstraint.activate(topBottomConstraints.customView)
                NSLayoutConstraint.activate(topBottomConstraints.accessory)
            }
        case .vertical:
            if currentState.isAccessoryHidden, currentState.isCustomViewHidden {
                NSLayoutConstraint.deactivate(leadingTrailingConstraints.accessory)
                NSLayoutConstraint.deactivate(leadingTrailingConstraints.customView)
                NSLayoutConstraint.deactivate(accessoryTopConstraints)
                NSLayoutConstraint.deactivate(customViewTopConstraints)
                NSLayoutConstraint.deactivate(accessoryFullVConstraints)
                NSLayoutConstraint.deactivate(customViewFullVConstraints)
            } else if currentState.isAccessoryHidden {
                NSLayoutConstraint.deactivate(leadingTrailingConstraints.accessory)
                NSLayoutConstraint.deactivate(accessoryTopConstraints)
                NSLayoutConstraint.deactivate(customViewTopConstraints)
                NSLayoutConstraint.deactivate(accessoryFullVConstraints)
                NSLayoutConstraint.activate(customViewFullVConstraints)
                NSLayoutConstraint.activate(leadingTrailingConstraints.customView)
            } else if currentState.isCustomViewHidden {
                NSLayoutConstraint.deactivate(leadingTrailingConstraints.customView)
                NSLayoutConstraint.deactivate(accessoryTopConstraints)
                NSLayoutConstraint.deactivate(customViewTopConstraints)
                NSLayoutConstraint.deactivate(customViewFullVConstraints)
                NSLayoutConstraint.activate(accessoryFullVConstraints)
                NSLayoutConstraint.activate(leadingTrailingConstraints.accessory)
            } else {
                NSLayoutConstraint.deactivate(accessoryFullVConstraints)
                NSLayoutConstraint.deactivate(customViewFullVConstraints)

                switch distribution {
                case .accessoryFirst:
                    guard !(accessoryTopConstraints.first?.isActive ?? false) else {
                        break
                    }
                    accessoryTopConstraints.first?.constant = -spacing
                    customViewTopConstraints.first?.constant = spacing
                    NSLayoutConstraint.deactivate(customViewTopConstraints)
                    NSLayoutConstraint.activate(accessoryTopConstraints)
                case .accessoryLast:
                    guard !(customViewTopConstraints.first?.isActive ?? false) else {
                        break
                    }
                    accessoryTopConstraints.first?.constant = spacing
                    customViewTopConstraints.first?.constant = -spacing
                    NSLayoutConstraint.deactivate(accessoryTopConstraints)
                    NSLayoutConstraint.activate(customViewTopConstraints)
                }
                NSLayoutConstraint.activate(leadingTrailingConstraints.customView)
                NSLayoutConstraint.activate(leadingTrailingConstraints.accessory)
            }
        }
        super.updateConstraints()
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        clipsToBounds = false

        addSubview(accessoryView)
        addSubview(customView)

        accessoryFirstObserver = accessoryView.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
            guard let self else {
                return
            }
            setNeedsUpdateConstraints()
        }
        customViewObserver = customView.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
            guard let self else {
                return
            }
            setNeedsUpdateConstraints()
        }
        setNeedsUpdateConstraints()
        setNeedsLayout()
    }

}
