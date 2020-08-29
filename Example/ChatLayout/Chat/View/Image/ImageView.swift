//
// ChatLayout
// ImageView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class ImageView: UIView, ContainerCollectionViewCellDelegate {

    private lazy var stackView = UIStackView(frame: bounds)

    private lazy var loadingIndicator = UIActivityIndicatorView(style: .gray)

    private lazy var imageView = UIImageView(frame: bounds)

    private var controller: ImageController!

    private var imageWidthConstraint: NSLayoutConstraint?

    private var imageHeightConstraint: NSLayoutConstraint?

    private var viewPortWidth: CGFloat = 300

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func prepareForReuse() {
        imageView.image = nil
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func setup(with controller: ImageController) {
        self.controller = controller
    }

    func reloadData() {
        UIView.performWithoutAnimation {
            switch controller.state {
            case .loading:
                loadingIndicator.isHidden = false
                imageView.isHidden = true
                imageView.image = nil
                stackView.removeArrangedSubview(imageView)
                stackView.addArrangedSubview(loadingIndicator)
                if !loadingIndicator.isAnimating {
                    loadingIndicator.startAnimating()
                }
                if #available(iOS 13.0, *) {
                    backgroundColor = .systemGray5
                } else {
                    backgroundColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
                }
                setupSize()
            case let .image(image):
                loadingIndicator.isHidden = true
                loadingIndicator.stopAnimating()
                imageView.isHidden = false
                imageView.image = image
                stackView.removeArrangedSubview(loadingIndicator)
                stackView.addArrangedSubview(imageView)
                setupSize()
                backgroundColor = .clear
            }
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isHidden = true

        let loadingWidthConstraint = loadingIndicator.widthAnchor.constraint(equalToConstant: 100)
        loadingWidthConstraint.priority = UILayoutPriority(999)
        loadingWidthConstraint.isActive = true

        let loadingHeightConstraint = loadingIndicator.heightAnchor.constraint(equalToConstant: 100)
        loadingHeightConstraint.priority = UILayoutPriority(999)
        loadingHeightConstraint.isActive = true

        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 310)
        imageWidthConstraint?.priority = UILayoutPriority(999)
        imageWidthConstraint?.isActive = true

        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 40)
        imageHeightConstraint?.priority = UILayoutPriority(999)
        imageHeightConstraint?.isActive = true
    }

    private func setupSize() {
        UIView.performWithoutAnimation {
            switch controller.state {
            case .loading:
                imageWidthConstraint?.isActive = false
                imageHeightConstraint?.isActive = false
                setNeedsLayout()
            case let .image(image):
                imageWidthConstraint?.isActive = true
                imageHeightConstraint?.isActive = true
                let maxWidth = min(viewPortWidth * Constants.maxWidth, image.size.width)
                imageWidthConstraint?.constant = maxWidth
                imageHeightConstraint?.constant = image.size.height * maxWidth / image.size.width
                setNeedsLayout()
            }
        }
    }

}
