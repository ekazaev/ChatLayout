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
import UIKit

// Just to visually test `ChatLayout.supportSelfSizingInvalidation`
protocol AvatarViewDelegate: AnyObject {
    func avatarTapped()
}

final class AvatarView: UIView, StaticViewFactory {
    weak var delegate: AvatarViewDelegate?

    private lazy var circleImageView = RoundedCornersContainerView<UIImageView>(frame: bounds)

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
        UIView.performWithoutAnimation {
            circleImageView.customView.image = controller.image
        }
        setNeedsLayout()
        updateBreakingPoints()
    }

    func setup(with controller: AvatarViewController) {
        self.controller = controller
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        addSubview(circleImageView)

        circleImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circleImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            circleImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            circleImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            circleImageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        let constraint = circleImageView.widthAnchor.constraint(equalToConstant: 30)
        constraint.priority = UILayoutPriority(rawValue: 999)
        constraint.isActive = true
        circleImageView.heightAnchor.constraint(equalTo: circleImageView.widthAnchor, multiplier: 1).isActive = true

        circleImageView.customView.contentMode = .scaleAspectFill

        let gestureRecogniser = UITapGestureRecognizer()
        circleImageView.addGestureRecognizer(gestureRecogniser)
        gestureRecogniser.addTarget(self, action: #selector(avatarTapped))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBreakingPoints()
    }

    private func updateBreakingPoints() {
        guard let controller else {
            return
        }
        if let cell = superview(of: UICollectionViewCell.self) {
            if !isHidden,
               controller.image != nil {
                let frame = cell.convert(circleImageView.bounds, from: circleImageView)
                print("A \(frame)")
                cell.replyBreak = (top: frame.minY - 5, bottom: frame.maxY + 5)
            } else {
                print("B")
                cell.replyBreak = nil
            }
        }
    }

    @objc
    private func avatarTapped() {
        delegate?.avatarTapped()
    }
}
