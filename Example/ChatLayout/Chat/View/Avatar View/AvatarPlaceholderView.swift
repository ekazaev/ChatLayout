//
// ChatLayout
// AvatarPlaceholderView.swift
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

final class AvatarPlaceholderView: NSUIView, StaticViewFactory {
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
#if canImport(UIKit)
        
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        
#endif
        let constraint = widthAnchor.constraint(equalToConstant: 30)
        constraint.priority = NSUILayoutPriority(rawValue: 999)
        constraint.isActive = true
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
    }
}
