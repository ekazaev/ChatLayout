//
// ChatLayout
// EdgeAligningView.swift
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

/// A container that can loosen selected edges of its `customView` from its layout margins.
///
/// When both edges of an axis are flexible, `customView` must provide its own size on that axis through intrinsic
/// content size or constraints.
public final class EdgeAligningView<CustomView: UIView>: UIView {
    /// Represents an edge of `EdgeAligningView`
    public enum Edge: CaseIterable {
        /// Top edge
        case top

        /// Leading edge
        case leading

        /// Trailing edge
        case trailing

        /// Bottom edge
        case bottom
    }

    /// Edges that may move away from the container's layout margins.
    public var flexibleEdges: Set<Edge> = [] {
        didSet {
            guard flexibleEdges != oldValue else {
                return
            }
            lastConstraintsUpdateEdges = nil
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }

    /// Contained view.
    public var customView: CustomView {
        didSet {
            guard customView !== oldValue else {
                return
            }
            oldValue.removeFromSuperview()
            setupContainer()
        }
    }

    /// Preferred priority of the internal constraints.
    public var preferredPriority: UILayoutPriority = .required {
        didSet {
            guard preferredPriority != oldValue else {
                return
            }
            managedConstraints.forEach { $0.priority = preferredPriority }
            setNeedsLayout()
        }
    }

    private var pinnedConstraints: [Edge: NSLayoutConstraint] = [:]

    private var minimumMarginConstraints: [Edge: NSLayoutConstraint] = [:]

    private var centeringConstraints: (centerX: NSLayoutConstraint, centerY: NSLayoutConstraint)?

    private var managedConstraints: [NSLayoutConstraint] = []

    private var lastConstraintsUpdateEdges: Set<Edge>?

    /// Initializes and returns a newly allocated `EdgeAligningView`
    /// - Parameters:
    ///   - customView: An instance of `CustomView`
    ///   - flexibleEdges: Set of edges to be set as loose.
    ///   - preferredPriority: Preferred priority of the internal constraints.
    public init(
        with customView: CustomView,
        flexibleEdges: Set<Edge> = [],
        preferredPriority: UILayoutPriority = .required
    ) {
        self.customView = customView
        self.flexibleEdges = flexibleEdges
        self.preferredPriority = preferredPriority
        super.init(frame: customView.frame)
        setupSubviews()
    }

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    public override init(frame: CGRect) {
        customView = CustomView(frame: frame)
        super.init(frame: frame)
        setupSubviews()
    }

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   - flexibleEdges: Set of edges to be set as loose.
    ///   - preferredPriority: Preferred priority of the internal constraints.
    ///   to the superview in which you plan to add it.
    public init(
        frame: CGRect,
        flexibleEdges: Set<Edge> = [],
        preferredPriority: UILayoutPriority = .required
    ) {
        customView = CustomView(frame: frame)
        self.flexibleEdges = flexibleEdges
        self.preferredPriority = preferredPriority
        super.init(frame: frame)
        setupSubviews()
    }

    /// This constructor is unavailable.
    @available(*, unavailable, message: "Use init(with:flexibleEdges:preferredPriority:) or init(frame:flexibleEdges:preferredPriority:) instead.")
    public required init?(coder: NSCoder) {
        fatalError("Use init(with:flexibleEdges:preferredPriority:) or init(frame:flexibleEdges:preferredPriority:) instead.")
    }

    /// A Boolean value that indicates whether the receiver depends on the constraint-based layout system.
    public override class var requiresConstraintBasedLayout: Bool {
        true
    }

    /// Updates constraints for the view.
    public override func updateConstraints() {
        guard lastConstraintsUpdateEdges != flexibleEdges else {
            super.updateConstraints()
            return
        }

        for edge in flexibleEdges {
            pinnedConstraints[edge]?.isActive = false
            minimumMarginConstraints[edge]?.isActive = true
        }
        for edge in Set(Edge.allCases).subtracting(flexibleEdges) {
            minimumMarginConstraints[edge]?.isActive = false
            pinnedConstraints[edge]?.isActive = true
        }
        centeringConstraints?.centerX.isActive = flexibleEdges.contains(.leading) && flexibleEdges.contains(.trailing)
        centeringConstraints?.centerY.isActive = flexibleEdges.contains(.top) && flexibleEdges.contains(.bottom)

        lastConstraintsUpdateEdges = flexibleEdges

        super.updateConstraints()
    }

    private func setupSubviews() {
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        setupContainer()
    }

    private func setupContainer() {
        if customView.superview != self {
            customView.removeFromSuperview()
            addSubview(customView)
        }
        customView.translatesAutoresizingMaskIntoConstraints = false
        if !managedConstraints.isEmpty {
            NSLayoutConstraint.deactivate(managedConstraints)
            managedConstraints.removeAll()
        }

        lastConstraintsUpdateEdges = nil

        let pinnedConstraints = buildPinnedConstraints(customView)
        let minimumMarginConstraints = buildMinimumMarginConstraints(customView)
        let centeringConstraints = buildCenteringConstraints(customView)

        managedConstraints.append(contentsOf: pinnedConstraints.values)
        managedConstraints.append(contentsOf: minimumMarginConstraints.values)
        managedConstraints.append(centeringConstraints.centerX)
        managedConstraints.append(centeringConstraints.centerY)

        self.pinnedConstraints = pinnedConstraints
        self.minimumMarginConstraints = minimumMarginConstraints
        self.centeringConstraints = centeringConstraints
        setNeedsUpdateConstraints()
        setNeedsLayout()
    }

    private func buildCenteringConstraints(_ view: UIView) -> (centerX: NSLayoutConstraint, centerY: NSLayoutConstraint) {
        (
            centerX: view.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor, priority: preferredPriority),
            centerY: view.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor, priority: preferredPriority)
        )
    }

    private func buildPinnedConstraints(_ view: UIView) -> [Edge: NSLayoutConstraint] {
        [
            .top: view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
            .bottom: view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
            .leading: view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
            .trailing: view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
        ]
    }

    private func buildMinimumMarginConstraints(_ view: UIView) -> [Edge: NSLayoutConstraint] {
        [
            .top: view.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
            .bottom: view.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
            .leading: view.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
            .trailing: view.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)
        ]
    }
}
