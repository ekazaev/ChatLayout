//
// ChatLayout
// MainContainerView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

final class MainContainerView<LeadingAccessory: StaticViewFactory, CustomView: NSUIView, TrailingAccessory: StaticViewFactory>: NSUIView, SwipeNotifierDelegate {
    var swipeCompletionRate: CGFloat = 0 {
        didSet {
            updateOffsets()
        }
    }

    var avatarView: LeadingAccessory.View? {
        containerView.leadingView
    }

    var customView: BezierMaskedView<CustomView> {
        containerView.customView
    }

    var statusView: TrailingAccessory.View? {
        containerView.trailingView
    }

    weak var accessoryConnectingView: NSUIView? {
        didSet {
            guard accessoryConnectingView != oldValue else {
                return
            }
            updateAccessoryView()
        }
    }

    var accessoryView = DateAccessoryView()

    var accessorySafeAreaInsets: NSUIEdgeInsets = .zero {
        didSet {
            guard accessorySafeAreaInsets != oldValue else {
                return
            }
            accessoryOffsetConstraint?.constant = accessorySafeAreaInsets.right
            setNeedsLayout()
            updateOffsets()
        }
    }

    private(set) lazy var containerView = CellLayoutContainerView<LeadingAccessory, BezierMaskedView<CustomView>, TrailingAccessory>()

    private weak var accessoryOffsetConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        layoutMargins = .zero
        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        #endif
        clipsToBounds = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])

        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        updateOffsets()
    }

    private func updateAccessoryView() {
        accessoryView.removeFromSuperview()
        guard let avatarConnectingView = accessoryConnectingView,
              let avatarConnectingSuperview = avatarConnectingView.superview else {
            return
        }
        avatarConnectingSuperview.addSubview(accessoryView)
        accessoryOffsetConstraint = accessoryView.leadingAnchor.constraint(equalTo: avatarConnectingView.trailingAnchor, constant: accessorySafeAreaInsets.right)
        accessoryOffsetConstraint?.isActive = true
        accessoryView.centerYAnchor.constraint(equalTo: avatarConnectingView.centerYAnchor).isActive = true
    }

    private func updateOffsets() {
        if let avatarView,
           !avatarView.isHidden {
            avatarView.transform = CGAffineTransform(translationX: -((avatarView.bounds.width + accessorySafeAreaInsets.left) * swipeCompletionRate), y: 0)
        }
        switch containerView.customView.messageType {
        case .incoming:
            customView.transform = .identity
            customView.transform = CGAffineTransform(translationX: -(customView.frame.origin.x * swipeCompletionRate), y: 0)
        case .outgoing:
            let maxOffset = min(frame.origin.x, accessoryView.frame.width)
            customView.transform = .identity
            customView.transform = CGAffineTransform(translationX: -(maxOffset * swipeCompletionRate), y: 0)
            if let statusView,
               !statusView.isHidden {
                statusView.transform = CGAffineTransform(translationX: -(maxOffset * swipeCompletionRate), y: 0)
            }
        }

        accessoryView.transform = CGAffineTransform(translationX: -((accessoryView.bounds.width + accessorySafeAreaInsets.right) * swipeCompletionRate), y: 0)
    }
}
