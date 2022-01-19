//
// ChatLayout
// StatusView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class StatusView: UIView, StaticViewFactory {

    private lazy var imageView = UIImageView(frame: bounds)

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
        addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 15)
        widthConstraint.priority = UILayoutPriority(rawValue: 999)
        widthConstraint.isActive = true
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 15)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true

        imageView.contentMode = .center
    }

    func setup(with status: MessageStatus) {
        switch status {
        case .sent:
            imageView.image = UIImage(named: "sent_status")
            imageView.tintColor = .lightGray
        case .received:
            imageView.image = UIImage(named: "sent_status")
            imageView.tintColor = .systemBlue
        case .read:
            imageView.image = UIImage(named: "read_status")
            imageView.tintColor = .systemBlue
        }
    }

}
