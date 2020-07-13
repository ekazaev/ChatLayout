//
// ChatLayout
// EdgeAligningView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
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

        var otherEdges: [Edge] {
            return Edge.allCases.filter { $0 != self }
        }

    }

    /// Set of edge constraints  to be set as loose.
    public var flexibleEdges: Set<Edge> = [] {
        didSet {
            guard flexibleEdges != oldValue else {
                return
            }
            setupContainer()
        }
    }

    /// Contained view.
    public var customView: CustomView {
        didSet {
            guard customView != oldValue else {
                return
            }
            oldValue.removeFromSuperview()
            setupContainer()
        }
    }

    private var addedConstraints: [NSLayoutConstraint] = []

    /// Initializes and returns a newly allocated `EdgeAligningView`
    /// - Parameters:
    ///   - alignedView: An instance of `CustomView`
    ///   - flexibleEdges: Set of edges to be set as loose.
    public init(with customView: CustomView, flexibleEdges: Set<Edge> = [.top]) {
        self.customView = customView
        self.flexibleEdges = flexibleEdges
        super.init(frame: customView.frame)
        setupContainer()
    }

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    public override init(frame: CGRect) {
        self.customView = CustomView(frame: frame)
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable, message: "Use init(with:flexibleEdges:) instead")
    /// This constructor is unavailable.
    public required init?(coder: NSCoder) {
        fatalError("Use init(with:flexibleEdges:) instead")
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
            removeConstraints(addedConstraints)
            addedConstraints.removeAll()
        }
        Set(Edge.allCases).subtracting(flexibleEdges).forEach { setConstraint(for: $0, on: customView, flexible: false) }
        flexibleEdges.forEach { setConstraint(for: $0, on: customView, flexible: true) }
        setDistributionConstraint(on: customView)
        setNeedsLayout()
    }

    private func setConstraint(for edge: Edge, on view: UIView, flexible: Bool = false) {
        var addedConstraints: [NSLayoutConstraint] = []
        switch edge {
        case .top:
            if flexible {
                addedConstraints.append(view.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor))
            } else {
                addedConstraints.append(view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor))
            }
        case .leading:
            if flexible {
                addedConstraints.append(view.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor))
            } else {
                addedConstraints.append(view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor))
            }
        case .trailing:
            if flexible {
                addedConstraints.append(view.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor))
            } else {
                addedConstraints.append(view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor))
            }
        case .bottom:
            if flexible {
                addedConstraints.append(view.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor))
            } else {
                addedConstraints.append(view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor))
            }
        }
        addedConstraints.forEach { constraint in
            constraint.isActive = true
        }
        self.addedConstraints.append(contentsOf: addedConstraints)
    }

    private func setDistributionConstraint(on view: UIView) {
        if flexibleEdges.contains(.leading), flexibleEdges.contains(.trailing) {
            let layoutConstraint = view.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor)
            addedConstraints.append(layoutConstraint)
            layoutConstraint.isActive = true
        } else if flexibleEdges.contains(.top), flexibleEdges.contains(.bottom) {
            let layoutConstraint = view.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor)
            addedConstraints.append(layoutConstraint)
            layoutConstraint.isActive = true
        }
    }

}
