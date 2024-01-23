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

    private var payload = VoidPayload()

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
        layer.shouldRasterize = false
    }

    func applyLayoutAttributes(_ attributes: LayoutAttributes, at state: RecyclerViewContainerState) {
        guard payload.isPinned,
              case let .final(state, container: containerSnapshot) = state,
              state != .disappearing else {
            return
        }
        if attributes.frame.minY.rounded() <= containerSnapshot.visibleRect.minY.rounded() + 8 {
            if layer.shadowOpacity == 0 {
                layer.shouldRasterize = false
                label.backgroundColor = .white
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    guard let self else {
                        return
                    }
                    layer.shadowRadius = 2
                    layer.shadowOpacity = 0.3
                    layer.shadowOffset = .zero
                }, completion: { [weak self] _ in
                    guard let self else {
                        return
                    }
                    layer.rasterizationScale = window?.screen.scale ?? 1
                    layer.shouldRasterize = true
                })
            }
        } else {
            if layer.shadowOpacity != 0 {
                layer.shouldRasterize = false
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    guard let self else {
                        return
                    }
                    layer.shadowRadius = 0
                    layer.shadowOpacity = 0
                    layer.shadowOffset = .zero
                }, completion: { [weak self] _ in
                    guard let self else {
                        return
                    }
                    label.backgroundColor = .clear
                    layer.rasterizationScale = window?.screen.scale ?? 1
                    layer.shouldRasterize = true
                })
            }
        }
    }

    func updateRecyclerItemPayload(_ payload: Any, index: Int) {
        guard let payload = payload as? VoidPayload else {
            return
        }
        self.payload = payload
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
