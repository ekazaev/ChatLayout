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
import UIKit

final class EditingAccessoryView: UIView, StaticViewFactory {
    private lazy var button = UIButton(type: .system)

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
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        button.setTitle("Delete", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
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

        UIView.animate(withDuration: duration) {
            self.isEditing = isEditing
            self.setNeedsLayout()
        }
    }
}
