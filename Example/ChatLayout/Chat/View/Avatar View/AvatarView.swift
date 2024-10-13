//
// ChatLayout
// AvatarView.swift
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

/// Just to visually test `ChatLayout.supportSelfSizingInvalidation`
protocol AvatarViewDelegate: AnyObject {
    func avatarTapped()
}

final class AvatarView: NSUIView, StaticViewFactory {
    weak var delegate: AvatarViewDelegate?

    private lazy var circleImageView = RoundedCornersContainerView<NSUIImageView>(frame: bounds)

    private var controller: AvatarViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func reloadData() {
        guard let controller else {
            return
        }
        NSUIView.performWithoutAnimation {
            circleImageView.customView.image = controller.image
        }
    }

    func setup(with controller: AvatarViewController) {
        self.controller = controller
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)

    override var isFlipped: Bool { true }

    #endif

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        #if canImport(UIKit)
        layoutMargins = .zero
        insetsLayoutMarginsFromSafeArea = false
        #endif
        addSubview(circleImageView)

        circleImageView.translatesAutoresizingMaskIntoConstraints = false
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        NSLayoutConstraint.activate([
            circleImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            circleImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            circleImageView.topAnchor.constraint(equalTo: topAnchor),
            circleImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        #endif

        #if canImport(UIKit)
        NSLayoutConstraint.activate([
            circleImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            circleImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            circleImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            circleImageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
        #endif

        let constraint = circleImageView.widthAnchor.constraint(equalToConstant: 30)
        constraint.priority = NSUILayoutPriority(rawValue: 999)
        constraint.isActive = true
        circleImageView.heightAnchor.constraint(equalTo: circleImageView.widthAnchor, multiplier: 1).isActive = true

        circleImageView.customView.contentMode = .scaleAspectFill

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        let gestureRecogniser = NSClickGestureRecognizer(target: self, action: #selector(avatarTapped))
        circleImageView.addGestureRecognizer(gestureRecogniser)
        #endif

        #if canImport(UIKit)
        let gestureRecogniser = UITapGestureRecognizer()
        circleImageView.addGestureRecognizer(gestureRecogniser)
        gestureRecogniser.addTarget(self, action: #selector(avatarTapped))
        #endif
    }

    @objc
    private func avatarTapped() {
        delegate?.avatarTapped()
    }
}
