//
// ChatLayout
// ImageView.swift
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
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

final class ImageView: NSUIView, ContainerCollectionViewCellDelegate {
    private lazy var stackView = NSUIStackView(frame: bounds)

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private lazy var loadingIndicator = NSProgressIndicator()
    #endif

    #if canImport(UIKit)
    private lazy var loadingIndicator = UIActivityIndicatorView(style: .gray)
    #endif

    private lazy var imageView = NSUIImageView(frame: bounds)

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

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    override func prepareForReuse() {
        imageView.image = nil
    }
    #endif

    #if canImport(UIKit)
    func prepareForReuse() {
        imageView.image = nil
    }
    #endif

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    // Uncomment to demonstrate the manual cell size calculation.
    // NB: Keep in mind that the cell itself is still using autolayout to layout it content. If you really want to speed up the
    // performance, You must layout the entire!!! `UICollectionCell` manually or using the tools
    // like [LayoutKit](https://github.com/linkedin/LayoutKit)
//    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes? {
//        viewPortWidth = layoutAttributes.layoutFrame.width
//        switch controller.state {
//        case .loading:
//            layoutAttributes.frame.size.height = 100
//            return layoutAttributes
//        case let .image(image):
//            let maxWidth = min(viewPortWidth * Constants.maxWidth, image.size.width)
//            layoutAttributes.frame.size.height = image.size.height * maxWidth / image.size.width
//            return layoutAttributes
//        }
//    }

    func setup(with controller: ImageController) {
        self.controller = controller
    }

    func reloadData() {
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
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            backgroundColor = NSUIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
            #endif

            #if canImport(UIKit)
            if #available(iOS 13.0, *) {
                backgroundColor = .systemGray5
            } else {
                backgroundColor = NSUIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
            }
            #endif
            setupSize()
        case let .image(image):
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            imageView.isHidden = false
            imageView.image = image
            stackView.removeArrangedSubview(loadingIndicator)
            stackView.addArrangedSubview(imageView)
            setupSize()
            stackView.setNeedsLayout()
            stackView.layoutIfNeeded()
            backgroundColor = .clear
        }
        #if canImport(UIKit)

        if let cell = superview(of: UICollectionViewCell.self) {
            cell.contentView.invalidateIntrinsicContentSize()
        }

        #endif
    }

    private func setupSubviews() {
        #if canImport(UIKit)

        layoutMargins = .zero
        insetsLayoutMarginsFromSafeArea = false

        #endif
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])

        imageView.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFill

        imageView.isHidden = true

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isHidden = true

        let loadingWidthConstraint = loadingIndicator.widthAnchor.constraint(equalToConstant: 100)
        loadingWidthConstraint.priority = NSUILayoutPriority(999)
        loadingWidthConstraint.isActive = true

        let loadingHeightConstraint = loadingIndicator.heightAnchor.constraint(equalToConstant: 100)
        loadingHeightConstraint.priority = NSUILayoutPriority(999)
        loadingHeightConstraint.isActive = true

        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 310)
        imageWidthConstraint?.priority = NSUILayoutPriority(999)

        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 40)
        imageHeightConstraint?.priority = NSUILayoutPriority(999)
    }

    private func setupSize() {
        NSUIView.performWithoutAnimation {
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
