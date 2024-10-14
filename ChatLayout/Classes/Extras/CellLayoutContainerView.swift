//
// ChatLayout
// CellLayoutContainerView.swift
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

/// Alignment for `CellLayoutContainerView` that corresponds to `UIStackView.Alignment`
public enum CellLayoutContainerViewAlignment {
    /// Align the top and bottom edges of horizontally stacked items tightly to the container.
    case fill

    /// Align the top edges of horizontally stacked items tightly to the container.
    case top

    /// Center items in a horizontal stack vertically.
    case center

    /// Align the bottom edges of horizontally stacked items tightly to the container.
    case bottom

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    fileprivate var stackAlignment: NSLayoutConstraint.Attribute {
        switch self {
        case .fill: return .centerY
        case .top: return .top
        case .center: return .centerY
        case .bottom: return .bottom
        }
    }
    #endif

    #if canImport(UIKit)
    fileprivate var stackAlignment: UIStackView.Alignment {
        switch self {
        case .fill: .fill
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        }
    }
    #endif
}

/// `CellLayoutContainerView` is a container view that helps to arrange the views in a horizontal cell-alike layout with an optional `LeadingAccessory` first,
/// a `CustomView` next and am optional `TrailingAccessory` last. Use `VoidViewFactory` to specify that `LeadingAccessory` or `TrailingAccessory` views should not be
/// allocated.

public final class CellLayoutContainerView<LeadingAccessory: StaticViewFactory, CustomView: NSUIView, TrailingAccessory: StaticViewFactory>: NSUIView {
    /// Leading accessory view.
    public lazy var leadingView: LeadingAccessory.View? = LeadingAccessory.buildView(within: bounds)

    /// Main view.
    public lazy var customView = CustomView(frame: bounds)

    /// Trailing accessory view.
    public lazy var trailingView: TrailingAccessory.View? = TrailingAccessory.buildView(within: bounds)

    /// Alignment that corresponds to `UIStackView.Alignment`
    public var alignment: CellLayoutContainerViewAlignment = .center {
        didSet {
            stackView.alignment = alignment.stackAlignment
        }
    }

    /// Default spacing between the views.
    public var spacing: CGFloat {
        get {
            stackView.spacing
        }
        set {
            stackView.spacing = newValue
        }
    }

    /// Custom spacing between the leading and main views.
    public var customLeadingSpacing: CGFloat {
        get {
            guard let leadingView else {
                return 0
            }
            return stackView.customSpacing(after: leadingView)
        }
        set {
            guard let leadingView else {
                return
            }
            return stackView.setCustomSpacing(newValue, after: leadingView)
        }
    }

    /// Custom spacing between the main and trailing views.
    public var customTrailingSpacing: CGFloat {
        get {
            stackView.customSpacing(after: customView)
        }
        set {
            stackView.setCustomSpacing(newValue, after: customView)
        }
    }

    private let stackView = NSUIStackView()

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
        stackView.orientation = .horizontal
        #endif

        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        stackView.axis = .horizontal
        #endif
        
        stackView.alignment = alignment.stackAlignment
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: customLayoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: customLayoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: customLayoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: customLayoutMarginsGuide.trailingAnchor),
        ])
        #endif

        #if canImport(UIKit)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
        #endif

        if let leadingAccessoryView = leadingView {
            stackView.addArrangedSubview(leadingAccessoryView)
            leadingAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        }

        stackView.addArrangedSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false

        if let trailingAccessoryView = trailingView {
            stackView.addArrangedSubview(trailingAccessoryView)
            trailingAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}
