//
// ChatLayout
// AutocompleteCell.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

open class AutocompleteCell: UITableViewCell {

    // MARK: - Properties

    open class var reuseIdentifier: String {
        return "AutocompleteCell"
    }

    /// A boarder line anchored to the top of the view
    public let separatorLine = SeparatorLine()

    open var imageViewEdgeInsets: UIEdgeInsets = .zero { didSet { setNeedsLayout() } }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        detailTextLabel?.text = nil
        imageView?.image = nil
        imageViewEdgeInsets = .zero
        separatorLine.backgroundColor = .lightGray
        separatorLine.isHidden = false
    }

    // MARK: - Setup

    private func setup() {

        setupSubviews()
        setupConstraints()
    }

    open func setupSubviews() {

        addSubview(separatorLine)
    }

    open func setupConstraints() {

        separatorLine.addConstraints(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, heightConstant: 0.5)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let imageViewFrame = imageView?.frame else { return }
        let imageViewOrigin = CGPoint(x: imageViewFrame.origin.x + imageViewEdgeInsets.left, y: imageViewFrame.origin.y + imageViewEdgeInsets.top)
        let imageViewSize = CGSize(width: imageViewFrame.size.width - imageViewEdgeInsets.left - imageViewEdgeInsets.right, height: imageViewFrame.size.height - imageViewEdgeInsets.top - imageViewEdgeInsets.bottom)
        imageView?.frame = CGRect(origin: imageViewOrigin, size: imageViewSize)
    }

    // MARK: - API [Public]

    @available(*, deprecated, message: "This function has been moved to the `AutocompleteManager`")
    open func attributedText(matching session: AutocompleteSession) -> NSMutableAttributedString {
        fatalError("Please use `func attributedText(matching:, fontSize:)` implemented in the `AutocompleteManager`")
    }
}
