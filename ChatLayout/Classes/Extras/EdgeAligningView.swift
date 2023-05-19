//
// ChatLayout
// EdgeAligningView.swift
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

/// Container view that allows its `CustomView` to have lose connection to the margins of the container according to the
/// settings provided in `EdgeAligningView.flexibleEdges`
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

    /// Set of edge constraints  to be set as loose.
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
            setupContainer()
        }
    }

    private var rigidConstraints: [Edge: NSLayoutConstraint] = [:]

    private var flexibleConstraints: [Edge: NSLayoutConstraint] = [:]

    private var centerConstraints: (centerX: NSLayoutConstraint, centerY: NSLayoutConstraint)?

    private var addedConstraints: [NSLayoutConstraint] = []

    private var lastConstraintsUpdateEdges: Set<Edge>?

    /// Initializes and returns a newly allocated `EdgeAligningView`
    /// - Parameters:
    ///   - customView: An instance of `CustomView`
    ///   - flexibleEdges: Set of edges to be set as loose.
    ///   - preferredPriority: Preferred priority of the internal constraints.
    public init(with customView: CustomView,
                flexibleEdges: Set<Edge> = [.top],
                preferredPriority: UILayoutPriority = .required) {
        self.customView = customView
        self.flexibleEdges = flexibleEdges
        self.preferredPriority = preferredPriority
        super.init(frame: customView.frame)
        setupContainer()
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
    public init(frame: CGRect,
                flexibleEdges: Set<Edge> = [],
                preferredPriority: UILayoutPriority = .required) {
        customView = CustomView(frame: frame)
        self.flexibleEdges = flexibleEdges
        self.preferredPriority = preferredPriority
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable, message: "Use init(with:flexibleEdges:) instead.")
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
        guard lastConstraintsUpdateEdges != flexibleEdges else {
            super.updateConstraints()
            return
        }

        flexibleEdges.forEach { edge in
            rigidConstraints[edge]?.isActive = false
            flexibleConstraints[edge]?.isActive = true
        }
        Set(Edge.allCases).subtracting(flexibleEdges).forEach { edge in
            flexibleConstraints[edge]?.isActive = false
            rigidConstraints[edge]?.isActive = true
        }
        centerConstraints?.centerX.isActive = flexibleEdges.contains(.leading) && flexibleEdges.contains(.trailing)
        centerConstraints?.centerY.isActive = flexibleEdges.contains(.top) && flexibleEdges.contains(.bottom)

        lastConstraintsUpdateEdges = flexibleEdges

        super.updateConstraints()
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
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
        if !addedConstraints.isEmpty {
            NSLayoutConstraint.deactivate(addedConstraints)
            addedConstraints.removeAll()
        }

        lastConstraintsUpdateEdges = nil

        let rigidConstraints = buildRigidConstraints(customView)
        let flexibleConstraints = buildFlexibleConstraints(customView)
        let centerConstraints = buildCenterConstraints(customView)

        addedConstraints.append(contentsOf: rigidConstraints.values)
        addedConstraints.append(contentsOf: flexibleConstraints.values)
        addedConstraints.append(centerConstraints.centerX)
        addedConstraints.append(centerConstraints.centerY)

        self.rigidConstraints = rigidConstraints
        self.flexibleConstraints = flexibleConstraints
        self.centerConstraints = centerConstraints
        setNeedsUpdateConstraints()
        setNeedsLayout()
    }

    private func buildCenterConstraints(_ view: UIView) -> (centerX: NSLayoutConstraint, centerY: NSLayoutConstraint) {
        (centerX: view.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor, priority: preferredPriority),
         centerY: view.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor, priority: preferredPriority))
    }

    private func buildRigidConstraints(_ view: UIView) -> [Edge: NSLayoutConstraint] {
        [.top: view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
         .bottom: view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
         .leading: view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
         .trailing: view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)]
    }

    private func buildFlexibleConstraints(_ view: UIView) -> [Edge: NSLayoutConstraint] {
        [.top: view.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor, priority: preferredPriority),
         .bottom: view.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor, priority: preferredPriority),
         .leading: view.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor, priority: preferredPriority),
         .trailing: view.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor, priority: preferredPriority)]
    }

}
