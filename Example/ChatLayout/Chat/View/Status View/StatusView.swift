//
// ChatLayout
// StatusView.swift
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

final class StatusView: NSUIView, StaticViewFactory {
    private lazy var imageView = NSUIImageView(frame: bounds)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    override var isFlipped: Bool { true }
#endif
    
    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        #if canImport(UIKit)
        layoutMargins = .zero
        insetsLayoutMarginsFromSafeArea = false
        #endif

        imageView.translatesAutoresizingMaskIntoConstraints = false
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: customLayoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: customLayoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: customLayoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: customLayoutMarginsGuide.bottomAnchor),
        ])
        #endif

        #if canImport(UIKit)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
        #endif
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 15)
        widthConstraint.priority = NSUILayoutPriority(rawValue: 999)
        widthConstraint.isActive = true
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 15)
        heightConstraint.priority = NSUILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true

        imageView.contentMode = .center
    }

    func setup(with status: MessageStatus) {
        switch status {
        case .sent:
            imageView.image = NSUIImage(named: "sent_status")
            imageView.tintColor = .lightGray
        case .received:
            imageView.image = NSUIImage(named: "sent_status")
            imageView.tintColor = .systemBlue
        case .read:
            imageView.image = NSUIImage(named: "read_status")
            imageView.tintColor = .systemBlue
        }
    }
}
