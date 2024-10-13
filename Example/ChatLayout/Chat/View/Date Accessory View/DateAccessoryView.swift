//
// ChatLayout
// DateAccessoryView.swift
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

final class DateAccessoryView: NSUIView {
    private var accessoryView = NSUILabel()

    private var controller: DateAccessoryController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func setup(with controller: DateAccessoryController) {
        self.controller = controller
        reloadData()
    }

    private func reloadData() {
        accessoryView.text = controller?.accessoryText
    }

    private func setupSubviews() {
        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        #endif

        translatesAutoresizingMaskIntoConstraints = false
        addSubview(accessoryView)
        
        NSLayoutConstraint.activate([
            accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])

        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        accessoryView.font = NSUIFont.preferredFont(forTextStyle: .caption1)
        accessoryView.textColor = .gray
    }
}
