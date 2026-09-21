//
// ChatLayout
// SwappingContainerView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// A container that arranges two views along a horizontal or vertical axis.
///
/// Hiding either view makes the other fill the arrangement axis.
public final class SwappingContainerView<CustomView: UIView, AccessoryView: UIView>: UIView {
    /// The axis along which the contained views are arranged.
    public enum Axis: Hashable {
        /// The views are arranged side by side.
        case horizontal

        /// The views are arranged one above the other.
        case vertical
    }

    /// The order of the contained views along the arrangement axis.
    public enum Distribution: Hashable {
        /// The `AccessoryView` should be positioned before the `CustomView`.
        case accessoryFirst

        /// The `AccessoryView` should be positioned after the `CustomView`.
        case accessoryLast
    }

    /// The order of the arranged subviews.
    public var distribution: Distribution = .accessoryFirst {
        didSet {
            guard distribution != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }

    /// The axis along which the contained views are arranged.
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
            accessoryFirstSpacingConstraint?.constant = -spacing
            customViewFirstSpacingConstraint?.constant = -spacing
            setNeedsLayout()
        }
    }

    /// Preferred priority of the internal constraints.
    public var preferredPriority: UILayoutPriority = .required {
        didSet {
            guard preferredPriority != oldValue else {
                return
            }
            updateConstraintPriorities()
            setNeedsLayout()
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
            accessoryViewObserver?.invalidate()
            accessoryViewObserver = nil
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

    private struct ConstraintState: Equatable {
        let distribution: Distribution

        let isAccessoryHidden: Bool

        let isCustomViewHidden: Bool
    }

    private struct ArrangementConstraints {
        let spacingConstraint: NSLayoutConstraint

        let constraints: [NSLayoutConstraint]
    }

    private var managedConstraints: [NSLayoutConstraint] = []

    private var accessoryFirstArrangementConstraints: [NSLayoutConstraint] = []

    private var accessoryFullSpanConstraints: [NSLayoutConstraint] = []

    private var customViewFirstArrangementConstraints: [NSLayoutConstraint] = []

    private var customViewFullSpanConstraints: [NSLayoutConstraint] = []

    private var crossAxisConstraints: (accessory: [NSLayoutConstraint], customView: [NSLayoutConstraint]) = (accessory: [], customView: [])

    private var accessoryFirstSpacingConstraint: NSLayoutConstraint?

    private var customViewFirstSpacingConstraint: NSLayoutConstraint?

    private var lastConstraintsState: ConstraintState?

    private var accessoryViewObserver: NSKeyValueObservation?

    private var customViewObserver: NSKeyValueObservation?

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   - axis: The view distribution axis.
    ///   - distribution: The layout of the arranged subviews along the axis.
    ///   - spacing: The distance in points between the edges of the contained views.
    ///   - preferredPriority: Preferred priority of the internal constraints.
    public init(
        frame: CGRect,
        axis: Axis = .horizontal,
        distribution: Distribution = .accessoryFirst,
        spacing: CGFloat = .zero,
        preferredPriority: UILayoutPriority = .required
    ) {
        customView = CustomView(frame: frame)
        accessoryView = AccessoryView(frame: frame)
        self.axis = axis
        self.distribution = distribution
        self.spacing = spacing
        self.preferredPriority = preferredPriority
        super.init(frame: frame)
        setupSubviews()
    }

    /// Initializes and returns a newly allocated container with the provided views.
    /// - Parameters:
    ///   - customView: The main view.
    ///   - accessoryView: The accessory view.
    ///   - axis: The view distribution axis.
    ///   - distribution: The layout of the contained views along the axis.
    ///   - spacing: The distance in points between the edges of the contained views.
    ///   - preferredPriority: Preferred priority of the internal constraints.
    public init(
        with customView: CustomView,
        accessoryView: AccessoryView,
        axis: Axis = .horizontal,
        distribution: Distribution = .accessoryFirst,
        spacing: CGFloat = .zero,
        preferredPriority: UILayoutPriority = .required
    ) {
        self.customView = customView
        self.accessoryView = accessoryView
        self.axis = axis
        self.distribution = distribution
        self.spacing = spacing
        self.preferredPriority = preferredPriority
        super.init(frame: customView.frame)
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

    /// This constructor is unavailable.
    @available(*, unavailable, message: "Use init(frame:axis:distribution:spacing:preferredPriority:) or init(with:accessoryView:axis:distribution:spacing:preferredPriority:) instead.")
    public required init?(coder: NSCoder) {
        fatalError("Use init(frame:axis:distribution:spacing:preferredPriority:) or init(with:accessoryView:axis:distribution:spacing:preferredPriority:) instead.")
    }

    /// A Boolean value that indicates whether the receiver depends on the constraint-based layout system.
    public override class var requiresConstraintBasedLayout: Bool {
        true
    }

    /// Updates constraints for the view.
    public override func updateConstraints() {
        let currentState = ConstraintState(
            distribution: distribution,
            isAccessoryHidden: accessoryView.isHidden,
            isCustomViewHidden: customView.isHidden
        )
        guard currentState != lastConstraintsState else {
            super.updateConstraints()
            return
        }

        lastConstraintsState = currentState

        if currentState.isAccessoryHidden, currentState.isCustomViewHidden {
            NSLayoutConstraint.deactivate(crossAxisConstraints.accessory)
            NSLayoutConstraint.deactivate(crossAxisConstraints.customView)
            NSLayoutConstraint.deactivate(accessoryFirstArrangementConstraints)
            NSLayoutConstraint.deactivate(customViewFirstArrangementConstraints)
            NSLayoutConstraint.deactivate(accessoryFullSpanConstraints)
            NSLayoutConstraint.deactivate(customViewFullSpanConstraints)
        } else if currentState.isAccessoryHidden {
            NSLayoutConstraint.deactivate(crossAxisConstraints.accessory)
            NSLayoutConstraint.deactivate(accessoryFirstArrangementConstraints)
            NSLayoutConstraint.deactivate(customViewFirstArrangementConstraints)
            NSLayoutConstraint.deactivate(accessoryFullSpanConstraints)
            NSLayoutConstraint.activate(customViewFullSpanConstraints)
            NSLayoutConstraint.activate(crossAxisConstraints.customView)
        } else if currentState.isCustomViewHidden {
            NSLayoutConstraint.deactivate(crossAxisConstraints.customView)
            NSLayoutConstraint.deactivate(accessoryFirstArrangementConstraints)
            NSLayoutConstraint.deactivate(customViewFirstArrangementConstraints)
            NSLayoutConstraint.deactivate(customViewFullSpanConstraints)
            NSLayoutConstraint.activate(accessoryFullSpanConstraints)
            NSLayoutConstraint.activate(crossAxisConstraints.accessory)
        } else {
            NSLayoutConstraint.deactivate(accessoryFullSpanConstraints)
            NSLayoutConstraint.deactivate(customViewFullSpanConstraints)

            switch distribution {
            case .accessoryFirst:
                NSLayoutConstraint.deactivate(customViewFirstArrangementConstraints)
                NSLayoutConstraint.activate(accessoryFirstArrangementConstraints)
            case .accessoryLast:
                NSLayoutConstraint.deactivate(accessoryFirstArrangementConstraints)
                NSLayoutConstraint.activate(customViewFirstArrangementConstraints)
            }
            NSLayoutConstraint.activate(crossAxisConstraints.customView)
            NSLayoutConstraint.activate(crossAxisConstraints.accessory)
        }

        super.updateConstraints()
    }

    private func setupSubviews() {
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        setupContainer()
    }

    private func setupContainer() {
        if !managedConstraints.isEmpty {
            NSLayoutConstraint.deactivate(managedConstraints)
            managedConstraints.removeAll()
        }

        customView.translatesAutoresizingMaskIntoConstraints = false
        if customView.superview != self {
            customView.removeFromSuperview()
            addSubview(customView)
        }

        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        if accessoryView.superview != self {
            accessoryView.removeFromSuperview()
            addSubview(accessoryView)
        }

        if accessoryViewObserver == nil {
            accessoryViewObserver = accessoryView.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated { [weak self] in
                    self?.setNeedsUpdateConstraints()
                }
            }
        }

        if customViewObserver == nil {
            customViewObserver = customView.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated { [weak self] in
                    self?.setNeedsUpdateConstraints()
                }
            }
        }

        lastConstraintsState = nil

        let accessoryFirstArrangement = buildAccessoryFirstArrangementConstraints()
        let accessoryFullSpanConstraints = buildAccessoryFullSpanConstraints()
        let customViewFirstArrangement = buildCustomViewFirstArrangementConstraints()
        let customViewFullSpanConstraints = buildCustomViewFullSpanConstraints()
        let crossAxisConstraints = buildCrossAxisConstraints()

        managedConstraints.append(contentsOf: accessoryFirstArrangement.constraints)
        managedConstraints.append(contentsOf: accessoryFullSpanConstraints)
        managedConstraints.append(contentsOf: customViewFirstArrangement.constraints)
        managedConstraints.append(contentsOf: customViewFullSpanConstraints)
        managedConstraints.append(contentsOf: crossAxisConstraints.customView)
        managedConstraints.append(contentsOf: crossAxisConstraints.accessory)

        accessoryFirstArrangementConstraints = accessoryFirstArrangement.constraints
        self.accessoryFullSpanConstraints = accessoryFullSpanConstraints
        customViewFirstArrangementConstraints = customViewFirstArrangement.constraints
        self.customViewFullSpanConstraints = customViewFullSpanConstraints
        self.crossAxisConstraints = crossAxisConstraints
        accessoryFirstSpacingConstraint = accessoryFirstArrangement.spacingConstraint
        customViewFirstSpacingConstraint = customViewFirstArrangement.spacingConstraint

        setNeedsUpdateConstraints()
        setNeedsLayout()
    }

    private func spacingPriority() -> UILayoutPriority {
        preferredPriority == .required ? .almostRequired : preferredPriority
    }

    private func updateConstraintPriorities() {
        managedConstraints.forEach { $0.priority = preferredPriority }
        accessoryFirstSpacingConstraint?.priority = spacingPriority()
        customViewFirstSpacingConstraint?.priority = spacingPriority()
    }

    private func buildAccessoryFirstArrangementConstraints() -> ArrangementConstraints {
        switch axis {
        case .horizontal:
            let spacingConstraint = accessoryView.trailingAnchor.constraint(equalTo: customView.leadingAnchor, constant: -spacing, priority: spacingPriority())
            return .init(
                spacingConstraint: spacingConstraint,
                constraints: [
                    spacingConstraint,
                    accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                    customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
                ]
            )
        case .vertical:
            let spacingConstraint = accessoryView.bottomAnchor.constraint(equalTo: customView.topAnchor, constant: -spacing, priority: spacingPriority())
            return .init(
                spacingConstraint: spacingConstraint,
                constraints: [
                    spacingConstraint,
                    accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                    customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)
                ]
            )
        }
    }

    private func buildCustomViewFirstArrangementConstraints() -> ArrangementConstraints {
        switch axis {
        case .horizontal:
            let spacingConstraint = customView.trailingAnchor.constraint(equalTo: accessoryView.leadingAnchor, constant: -spacing, priority: spacingPriority())
            return .init(
                spacingConstraint: spacingConstraint,
                constraints: [
                    spacingConstraint,
                    customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                    accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
                ]
            )
        case .vertical:
            let spacingConstraint = customView.bottomAnchor.constraint(equalTo: accessoryView.topAnchor, constant: -spacing, priority: spacingPriority())
            return .init(
                spacingConstraint: spacingConstraint,
                constraints: [
                    spacingConstraint,
                    customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                    accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)
                ]
            )
        }
    }

    private func buildAccessoryFullSpanConstraints() -> [NSLayoutConstraint] {
        switch axis {
        case .horizontal:
            [
                accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
            ]
        case .vertical:
            [
                accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)
            ]
        }
    }

    private func buildCustomViewFullSpanConstraints() -> [NSLayoutConstraint] {
        switch axis {
        case .horizontal:
            [
                customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
            ]
        case .vertical:
            [
                customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)
            ]
        }
    }

    private func buildCrossAxisConstraints() -> (accessory: [NSLayoutConstraint], customView: [NSLayoutConstraint]) {
        switch axis {
        case .horizontal:
            (
                accessory: [
                    accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                    accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)
                ],
                customView: [
                    customView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
                    customView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority)
                ]
            )
        case .vertical:
            (
                accessory: [
                    accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                    accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
                ],
                customView: [
                    customView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
                    customView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
                ]
            )
        }
    }
}
