//
// ChatLayout
// ImageAttachmentCell.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

open class ImageAttachmentCell: AttachmentCell {

    // MARK: - Properties

    public override class var reuseIdentifier: String {
        return "ImageAttachmentCell"
    }

    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    // MARK: - Setup

    private func setup() {
        containerView.addSubview(imageView)
        imageView.fillSuperview()
    }
}
