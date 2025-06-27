//
// ChatLayout
// DateSeparatorView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
import UIKit

final class DateSeparatorView: UIView, StaticViewFactory {
    private lazy var borderView = {
        let view = UIView()
        view.backgroundColor = .white
        view.frame = bounds.insetBy(dx: -5, dy: -5)
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.gray.cgColor
        return view
    }()

    private(set) lazy var labelView: UILabel = {
        let view = UILabel()
        view.textColor = .gray
        view.font = .preferredFont(forTextStyle: .caption2)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderView.layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        addSubview(borderView)
        addSubview(labelView)

        borderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            borderView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            borderView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        labelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 5),
            labelView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -5),
            labelView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 5),
            labelView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -5)
        ])
    }
}
