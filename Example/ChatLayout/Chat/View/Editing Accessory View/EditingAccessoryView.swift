//
// ChatLayout
// EditingAccessoryView.swift
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

final class EditingAccessoryView: NSUIView, StaticViewFactory {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private lazy var button = NSButton()
    #endif

    #if canImport(UIKit)
    private lazy var button = UIButton(type: .system)
    #endif

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    private var controller: EditingAccessoryController?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        #endif
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        button.title = "Delete"
        button.target = self
        button.action = #selector(buttonTapped)
        #endif

        #if canImport(UIKit)
        button.setTitle("Delete", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        #endif
    }

    func setup(with controller: EditingAccessoryController) {
        self.controller = controller
    }

    @objc
    private func buttonTapped() {
        controller?.deleteButtonTapped()
    }
}

extension EditingAccessoryView: EditNotifierDelegate {
    var isEditing: Bool {
        get {
            !isHidden
        }
        set {
            guard isHidden == newValue else {
                return
            }
            isHidden = !newValue
            alpha = newValue ? 1 : 0
        }
    }

    public func setIsEditing(_ isEditing: Bool, duration: ActionDuration = .notAnimated) {
        guard case let .animated(duration) = duration else {
            self.isEditing = isEditing
            return
        }

        NSUIView.animate(withDuration: duration) {
            self.isEditing = isEditing
            self.setNeedsLayout()
        }
    }
}
