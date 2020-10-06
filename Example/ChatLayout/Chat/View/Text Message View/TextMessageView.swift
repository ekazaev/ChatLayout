//
// ChatLayout
// TextMessageView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class TextMessageView: UIView, ContainerCollectionViewCellDelegate {

    private var viewPortWidth: CGFloat = 300

    private lazy var label = UILabel()

    private var controller: TextMessageController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
    }

    func setup(with controller: TextMessageController) {
        self.controller = controller
        reloadData()
    }

    func reloadData() {
        guard let controller = controller else {
            return
        }
        label.text = controller.text
        if #available(iOS 13.0, *) {
            label.textColor = controller.type.isIncoming ? .label : .systemBackground
        } else {
            label.textColor = controller.type.isIncoming ? .black : .white
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true

        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0

        setupSize()
    }

    private func setupSize() {
        UIView.performWithoutAnimation {
            self.label.preferredMaxLayoutWidth = viewPortWidth * Constants.maxWidth
            setNeedsLayout()
        }
    }

}
