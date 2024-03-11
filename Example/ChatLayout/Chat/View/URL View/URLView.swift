//
// ChatLayout
// URLView.swift
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
import LinkPresentation
import UIKit

@available(iOS 13, *)
final class URLView: UIView, ContainerCollectionViewCellDelegate {
    private var linkView: LPLinkView?

    private var controller: URLController?

    private var viewPortWidth: CGFloat = 300

    private var linkWidthConstraint: NSLayoutConstraint?

    private var linkHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
    }

    func prepareForReuse() {
        linkView?.removeFromSuperview()
        linkView = nil
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func reloadData() {
        setupLinkView()
        if let cell = superview(of: UICollectionViewCell.self) {
            cell.contentView.invalidateIntrinsicContentSize()
        }
    }

    func setup(with controller: URLController) {
        self.controller = controller
    }

    private func setupLinkView() {
        // I could not make it to present itself without animation on update. So I completely remove it from the stack.
        // raywenderlich.com does the same, so I did not want to waste time.
        // Also it has weird issue that it does not updates website name if you update metadata like this.
//        if let linkView = linkView,
//           let metadata = controller?.metadata {
//            UIView.performWithoutAnimation {
//                linkView.metadata = metadata
//                setupSize()
//            }
//            return
//        }
        linkView?.removeFromSuperview()
        guard let controller else {
            return
        }

        let newLinkView: LPLinkView
        switch controller.metadata {
        case let .some(metadata):
            newLinkView = LPLinkView(metadata: metadata)
        case .none:
            newLinkView = LPLinkView(url: controller.url)
        }
        addSubview(newLinkView)
        newLinkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newLinkView.topAnchor.constraint(equalTo: topAnchor),
            newLinkView.bottomAnchor.constraint(equalTo: bottomAnchor),
            newLinkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newLinkView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        linkWidthConstraint = newLinkView.widthAnchor.constraint(equalToConstant: 310)
        linkWidthConstraint?.priority = UILayoutPriority(999)
        linkWidthConstraint?.isActive = true

        linkHeightConstraint = newLinkView.heightAnchor.constraint(equalToConstant: 40)
        linkHeightConstraint?.priority = UILayoutPriority(999)
        linkHeightConstraint?.isActive = true

        linkView = newLinkView
    }

    private func setupSize() {
        guard let linkView else {
            return
        }
        let contentSize = linkView.intrinsicContentSize
        let maxWidth = min(viewPortWidth * Constants.maxWidth, contentSize.width)

        let newContentRect = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: contentSize.height * maxWidth / contentSize.width))

        linkWidthConstraint?.constant = newContentRect.width
        linkHeightConstraint?.constant = newContentRect.height

        linkView.bounds = newContentRect
        // It is funny that since IOS 14 it can give slightly different values depending if it was drawn before or not.
        // Thank you Apple. Dont be surprised that the web preview may lightly jump and cause the small jumps
        // of the whole layout.
        linkView.sizeToFit()

        setNeedsLayout()
        layoutIfNeeded()
    }
}
