//
// ChatLayout
// DateGroupView.swift
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

final class DateGroupView: UIView, ContainerCollectionViewCellDelegate {

    private var viewPortWidth: CGFloat = 300

    private lazy var label = EdgeAligningView<UILabel>()

    private var controller: TextMessageController?

    private var textViewWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func prepareForReuse() {}

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func applyWidth(_ width: CGFloat) {
        viewPortWidth = width
        setupSize()
    }

    func setup(with string: String) {
        label.customView.text = string
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        backgroundColor = .clear

        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor)
        ])

        label.customView.textAlignment = .center
        label.customView.textColor = .gray
        label.backgroundColor = .white
        label.customView.numberOfLines = 0
        label.customView.font = .preferredFont(forTextStyle: .caption2)
        label.clipsToBounds = true
        label.layoutMargins = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
    }

    private func setupSize() {
        UIView.performWithoutAnimation {
            label.customView.preferredMaxLayoutWidth = viewPortWidth
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.layer.cornerRadius = label.frame.height / 2
    }
}
