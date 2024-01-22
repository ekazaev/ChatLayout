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
import RecyclerView
import UIKit

final class DateGroupView: UIView, ContainerCollectionViewCellDelegate, RecyclerViewCellEvenHandler {

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

    func prepareForDequeue() {
        layer.removeAllAnimations()
    }

    func applyLayoutAttributes(_ attributes: LayoutAttributes, at state: RecyclerViewContainerState) {
        guard case let .final(state, container: containerSnapshot) = state,
              state != .disappearing else {
            return
        }
        if attributes.frame.minY.rounded() <= containerSnapshot.visibleRect.minY.rounded() + 8 {
            if layer.shadowOpacity == 0 {
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    guard let self else {
                        return
                    }
                    layer.shadowRadius = 2
                    layer.shadowOpacity = 0.3
                    layer.shadowOffset = .zero
                })
                label.backgroundColor = .white
            }
        } else {
            if layer.shadowOpacity != 0 {
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    guard let self else {
                        return
                    }
                    layer.shadowRadius = 0
                    layer.shadowOpacity = 0
                    layer.shadowOffset = .zero
                })
                label.backgroundColor = .clear
            }
        }
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

        label.customView.adjustsFontForContentSizeCategory = true
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
