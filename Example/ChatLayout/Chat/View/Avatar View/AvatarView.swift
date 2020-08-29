//
// ChatLayout
// AvatarView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class AvatarView: UIView, StaticViewFactory {

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
        guard let controller = controller else {
            return
        }
        UIView.performWithoutAnimation {
            circleImageView.customView.image = controller.image
        }
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
        circleImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        circleImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        circleImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        circleImageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true

        let constraint = circleImageView.widthAnchor.constraint(equalToConstant: 30)
        constraint.priority = UILayoutPriority(rawValue: 999)
        constraint.isActive = true
        circleImageView.heightAnchor.constraint(equalTo: circleImageView.widthAnchor, multiplier: 1).isActive = true

        circleImageView.customView.contentMode = .scaleAspectFill
    }

}
