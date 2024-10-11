//
// ChatLayout
// SwappingContainerView.swift
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

/// This container view is designed to hold two `UIView` elements and arrange them in a horizontal or vertical axis.
/// It also allows to easily change the order of the views if needed.

public final class SwappingContainerView<CustomView: NSUIView, AccessoryView: NSUIView>: NSUIView {
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
            setupContainer()
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

    /// Preferred priority of the internal constraints.
    public var preferredPriority: NSUILayoutPriority = .required {
        didSet {
            guard preferredPriority != oldValue else {
                return
            }
            setupContainer()
        }
    }

    /// Contained accessory view.
    public var accessoryView: AccessoryView {
        didSet {
            guard accessoryView !== oldValue else {
                return
            }
            if oldValue.superview === self {
                oldValue.removeFromSuperview()
            }
            accessoryFirstObserver?.invalidate()
            accessoryFirstObserver = nil
            setupContainer()
        }
    }

    /// Contained main view.
    public var customView: CustomView {
        didSet {
            guard customView !== oldValue else {
                return
            }
            if oldValue.superview === self {
                oldValue.removeFromSuperview()
            }
            customViewObserver?.invalidate()
            customViewObserver = nil
            setupContainer()
        }
    }

    private struct SwappingContainerState: Equatable {
        let axis: Axis

        let distribution: Distribution

        let spacing: CGFloat

        let isAccessoryHidden: Bool

        let isCustomViewHidden: Bool
    }

    private var addedConstraints: [NSLayoutConstraint] = []

    private var accessoryFirstConstraints: [NSLayoutConstraint] = []

    private var accessoryFullConstraints: [NSLayoutConstraint] = []

    private var customViewFirstConstraints: [NSLayoutConstraint] = []

    private var customViewFullConstraints: [NSLayoutConstraint] = []

    private var edgeConstraints: (accessory: [NSLayoutConstraint], customView: [NSLayoutConstraint]) = (accessory: [], customView: [])

    private var cachedState: SwappingContainerState?

    private var accessoryFirstObserver: NSKeyValueObservation?

    private var customViewObserver: NSKeyValueObservation?

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   - axis: The view distribution axis.
    ///   - distribution: The layout of the arranged subviews along the axis.
    ///   - spacing: The distance in points between the edges of the contained views.
    ///   - preferredPriority: Preferred priority of the internal constraints.
    ///   to the superview in which you plan to add it.
    public init(frame: CGRect,
                axis: Axis = .horizontal,
                distribution: Distribution = .accessoryFirst,
                spacing: CGFloat,
                preferredPriority: NSUILayoutPriority = .required) {
        self.customView = CustomView(frame: frame)
        self.accessoryView = AccessoryView(frame: frame)
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
        self.customView = CustomView(frame: frame)
        self.accessoryView = AccessoryView(frame: frame)
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable, message: "Use init(frame:) instead.")
    /// This constructor is unavailable.
    public required init?(coder: NSCoder) {
        fatalError("Use init(with:flexibleEdges:) instead.")
    }

    /// A Boolean value that indicates whether the receiver depends on the constraint-based layout system.
    public override class var requiresConstraintBasedLayout: Bool {
        true
    }

    /// Updates constraints for the view.
    public override func updateConstraints() {
        let currentState = SwappingContainerState(
            axis: axis,
            distribution: distribution,
            spacing: spacing,
            isAccessoryHidden: accessoryView.isHidden,
            isCustomViewHidden: customView.isHidden
        )
        guard currentState != cachedState else {
            super.updateConstraints()
            return
        }

        cachedState = currentState

        if currentState.isAccessoryHidden, currentState.isCustomViewHidden {
            NSLayoutConstraint.deactivate(edgeConstraints.accessory)
            NSLayoutConstraint.deactivate(edgeConstraints.customView)
            NSLayoutConstraint.deactivate(accessoryFirstConstraints)
            NSLayoutConstraint.deactivate(customViewFirstConstraints)
            NSLayoutConstraint.deactivate(accessoryFullConstraints)
            NSLayoutConstraint.deactivate(customViewFullConstraints)
        } else if currentState.isAccessoryHidden {
            NSLayoutConstraint.deactivate(edgeConstraints.accessory)
            NSLayoutConstraint.deactivate(accessoryFirstConstraints)
            NSLayoutConstraint.deactivate(customViewFirstConstraints)
            NSLayoutConstraint.deactivate(accessoryFullConstraints)
            NSLayoutConstraint.activate(customViewFullConstraints)
            NSLayoutConstraint.activate(edgeConstraints.customView)
        } else if currentState.isCustomViewHidden {
            NSLayoutConstraint.deactivate(edgeConstraints.customView)
            NSLayoutConstraint.deactivate(accessoryFirstConstraints)
            NSLayoutConstraint.deactivate(customViewFirstConstraints)
            NSLayoutConstraint.deactivate(customViewFullConstraints)
            NSLayoutConstraint.activate(accessoryFullConstraints)
            NSLayoutConstraint.activate(edgeConstraints.accessory)
        } else {
            NSLayoutConstraint.deactivate(accessoryFullConstraints)
            NSLayoutConstraint.deactivate(customViewFullConstraints)

            switch distribution {
            case .accessoryFirst:
                guard !(accessoryFirstConstraints.first?.isActive ?? false) else {
                    accessoryFirstConstraints.first?.constant = -spacing
                    break
                }
                accessoryFirstConstraints.first?.constant = -spacing
                customViewFirstConstraints.first?.constant = spacing
                NSLayoutConstraint.deactivate(customViewFirstConstraints)
                NSLayoutConstraint.activate(accessoryFirstConstraints)
            case .accessoryLast:
                guard !(customViewFirstConstraints.first?.isActive ?? false) else {
                    customViewFirstConstraints.first?.constant = -spacing
                    break
                }
                accessoryFirstConstraints.first?.constant = spacing
                customViewFirstConstraints.first?.constant = -spacing
                NSLayoutConstraint.deactivate(accessoryFirstConstraints)
                NSLayoutConstraint.activate(customViewFirstConstraints)
            }
            NSLayoutConstraint.activate(edgeConstraints.customView)
            NSLayoutConstraint.activate(edgeConstraints.accessory)
        }

        super.updateConstraints()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public override var isFlipped: Bool { true }
    #endif

    private func setupSubviews() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        setWantsLayer()
        #endif
        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        #endif
        clipsToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
        setupContainer()
    }

    private func setupContainer() {
        if !addedConstraints.isEmpty {
            NSLayoutConstraint.deactivate(addedConstraints)
            addedConstraints.removeAll()
        }

        if customView.superview != self {
            customView.translatesAutoresizingMaskIntoConstraints = false
            customView.removeFromSuperview()
            addSubview(customView)
        }

        if accessoryView.superview != self {
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            accessoryView.removeFromSuperview()
            addSubview(accessoryView)
        }

        if accessoryFirstObserver == nil {
            accessoryFirstObserver = accessoryView.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
                guard let self else {
                    return
                }
                setNeedsUpdateConstraints()
            }
        }

        if customViewObserver == nil {
            customViewObserver = customView.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
                guard let self else {
                    return
                }
                setNeedsUpdateConstraints()
            }
        }

        cachedState = nil

        let accessoryFirstConstraints = buildAccessoryFirstConstraints()
        let accessoryFullConstraints = buildAccessoryFullConstraints()
        let customViewFirstConstraints = buildCustomViewFirstConstraints()
        let customViewFullConstraints = buildCustomViewFullConstraints()
        let edgeConstraints = buildEdgeConstraints()

        addedConstraints.append(contentsOf: accessoryFirstConstraints)
        addedConstraints.append(contentsOf: accessoryFullConstraints)
        addedConstraints.append(contentsOf: customViewFirstConstraints)
        addedConstraints.append(contentsOf: customViewFullConstraints)
        addedConstraints.append(contentsOf: edgeConstraints.customView)
        addedConstraints.append(contentsOf: edgeConstraints.accessory)

        self.accessoryFirstConstraints = accessoryFirstConstraints
        self.accessoryFullConstraints = accessoryFullConstraints
        self.customViewFirstConstraints = customViewFirstConstraints
        self.customViewFullConstraints = customViewFullConstraints
        self.edgeConstraints = edgeConstraints

        setNeedsUpdateConstraints()
        setNeedsLayout()
    }

    private func spacingPriority() -> NSUILayoutPriority {
        preferredPriority == .required ? .almostRequired : preferredPriority
    }

    private func buildAccessoryFirstConstraints() -> [NSLayoutConstraint] {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        switch axis {
        case .horizontal:
            return [
                accessoryView.trailingAnchor.constraint(equalTo: customView.leadingAnchor, constant: spacing, priority: spacingPriority()),
                accessoryView.leadingAnchor.constraint(equalTo: leadingAnchor, priority: preferredPriority),
                customView.trailingAnchor.constraint(equalTo: trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                accessoryView.bottomAnchor.constraint(equalTo: customView.topAnchor, constant: spacing, priority: spacingPriority()),
                accessoryView.topAnchor.constraint(equalTo: topAnchor, priority: preferredPriority),
                customView.bottomAnchor.constraint(equalTo: bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif

        #if canImport(UIKit)
        switch axis {
        case .horizontal:
            return [
                accessoryView.trailingAnchor.constraint(equalTo: customView.leadingAnchor, constant: spacing, priority: spacingPriority()),
                accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                accessoryView.bottomAnchor.constraint(equalTo: customView.topAnchor, constant: spacing, priority: spacingPriority()),
                accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif
    }

    private func buildCustomViewFirstConstraints() -> [NSLayoutConstraint] {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        switch axis {
        case .horizontal:
            return [
                customView.trailingAnchor.constraint(equalTo: accessoryView.leadingAnchor, constant: -spacing, priority: spacingPriority()),
                customView.leadingAnchor.constraint(equalTo: leadingAnchor, priority: preferredPriority),
                accessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                customView.bottomAnchor.constraint(equalTo: accessoryView.topAnchor, constant: -spacing, priority: spacingPriority()),
                customView.topAnchor.constraint(equalTo: topAnchor, priority: preferredPriority),
                accessoryView.bottomAnchor.constraint(equalTo: bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif

        #if canImport(UIKit)
        switch axis {
        case .horizontal:
            return [
                customView.trailingAnchor.constraint(equalTo: accessoryView.leadingAnchor, constant: -spacing, priority: spacingPriority()),
                customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                customView.bottomAnchor.constraint(equalTo: accessoryView.topAnchor, constant: -spacing, priority: spacingPriority()),
                customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif
    }

    private func buildAccessoryFullConstraints() -> [NSLayoutConstraint] {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        switch axis {
        case .horizontal:
            return [
                accessoryView.leadingAnchor.constraint(equalTo: leadingAnchor, priority: preferredPriority),
                accessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                accessoryView.topAnchor.constraint(equalTo: topAnchor, priority: preferredPriority),
                accessoryView.bottomAnchor.constraint(equalTo: bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif

        #if canImport(UIKit)
        switch axis {
        case .horizontal:
            return [
                accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif
    }

    private func buildCustomViewFullConstraints() -> [NSLayoutConstraint] {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        switch axis {
        case .horizontal:
            return [
                customView.leadingAnchor.constraint(equalTo: leadingAnchor, priority: preferredPriority),
                customView.trailingAnchor.constraint(equalTo: trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                customView.topAnchor.constraint(equalTo: topAnchor, priority: preferredPriority),
                customView.bottomAnchor.constraint(equalTo: bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif

        #if canImport(UIKit)
        switch axis {
        case .horizontal:
            return [
                customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority),
            ]
        case .vertical:
            return [
                customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
            ]
        }
        #endif
    }

    private func buildEdgeConstraints() -> (accessory: [NSLayoutConstraint], customView: [NSLayoutConstraint]) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        switch axis {
        case .horizontal:

            return (
                accessory: [accessoryView.topAnchor.constraint(equalTo: topAnchor, priority: preferredPriority),
                            accessoryView.bottomAnchor.constraint(equalTo: bottomAnchor, priority: preferredPriority)],
                customView: [customView.topAnchor.constraint(equalTo: topAnchor, priority: preferredPriority),
                             customView.bottomAnchor.constraint(equalTo: bottomAnchor, priority: preferredPriority)]
            )
        case .vertical:
            return (
                accessory: [accessoryView.leadingAnchor.constraint(equalTo: leadingAnchor, priority: preferredPriority),
                            accessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, priority: preferredPriority)],
                customView: [customView.leadingAnchor.constraint(equalTo: leadingAnchor, priority: preferredPriority),
                             customView.trailingAnchor.constraint(equalTo: trailingAnchor, priority: preferredPriority)]
            )
        }
        #endif

        #if canImport(UIKit)
        switch axis {
        case .horizontal:

            return (
                accessory: [accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                            accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)],
                customView: [customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                             customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)]
            )
        case .vertical:
            return (
                accessory: [accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                            accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)],
                customView: [customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                             customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)]
            )
        }
        #endif
    }
}
