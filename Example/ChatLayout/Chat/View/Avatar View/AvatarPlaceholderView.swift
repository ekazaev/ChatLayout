//
// ChatLayout
// AvatarPlaceholderView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class AvatarPlaceholderView: UIView, StaticViewFactory {

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
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        let constraint = widthAnchor.constraint(equalToConstant: 30)
        constraint.priority = UILayoutPriority(rawValue: 999)
        constraint.isActive = true
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
    }

}
