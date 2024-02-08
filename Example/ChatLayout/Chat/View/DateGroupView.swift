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

    private var isPinnedState = false

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
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        layer.shadowOffset = .zero
        label.backgroundColor = .clear
        isPinnedState = false
    }

    func applyLayoutAttributes(_ attributes: LayoutAttributes, at state: RecyclerViewContainerState, index: Int) {
        guard payload.isPinned,
              case let .final(state, container: containerSnapshot) = state,
              state != .disappearing else {
            return
        }

        let containerMinY = (containerSnapshot.visibleRect.minY + 8).rounded(.up)
        let cellY = attributes.frame.minY.rounded(.up)
        let maxOffsetY: CGFloat = attributes.frame.height * 2.5
        let distance = cellY >= containerMinY ? cellY - containerMinY : 0
        let absDistance = min(maxOffsetY, abs(distance))
        let coefficient = absDistance / maxOffsetY
        let oppositeCoefficient = 1 - coefficient

        layer.shadowRadius = 2 * oppositeCoefficient
        layer.shadowOpacity = Float(0.3 * oppositeCoefficient)
        if coefficient == 1,
           layer.shouldRasterize {
            layer.shouldRasterize = false
            label.backgroundColor = .clear
            isPinnedState = false
        } else {
            if !isPinnedState {
                label.backgroundColor = .systemBackground
                isPinnedState = true
            }
            if coefficient == 0,
               !layer.shouldRasterize {
                layer.rasterizationScale = window?.screen.scale ?? 1
                layer.shouldRasterize = true
            }
        }
        setupCornerRadius()
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
        label.backgroundColor = .clear
        label.customView.numberOfLines = 0
        label.customView.font = .preferredFont(forTextStyle: .caption2)
        label.clipsToBounds = true
        label.layoutMargins = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)

        layer.shadowOffset = .zero
    }

    private func setupSize() {
        UIView.performWithoutAnimation {
            label.customView.preferredMaxLayoutWidth = viewPortWidth
        }
    }

    private func setupCornerRadius() {
        if isPinnedState {
            label.layer.cornerRadius = label.frame.height / 2
        } else {
            label.layer.cornerRadius = 0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupCornerRadius()
    }
}
