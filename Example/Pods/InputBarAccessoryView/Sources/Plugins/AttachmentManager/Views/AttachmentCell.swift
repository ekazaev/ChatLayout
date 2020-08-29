//
// ChatLayout
// AttachmentCell.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

open class AttachmentCell: UICollectionViewCell {

    // MARK: - Properties

    public class var reuseIdentifier: String {
        return "AttachmentCell"
    }

    public let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .groupTableViewBackground
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    open var padding: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5) {
        didSet {
            updateContainerPadding()
        }
    }

    open lazy var deleteButton: UIButton = { [weak self] in
        let button = UIButton()
        button.setAttributedTitle(NSMutableAttributedString().bold("X", fontSize: 15, textColor: .white), for: .normal)
        button.setAttributedTitle(NSMutableAttributedString().bold("X", fontSize: 15, textColor: UIColor.white.withAlphaComponent(0.5)), for: .highlighted)
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.backgroundColor = UIColor(red: 0, green: 122 / 255, blue: 1, alpha: 1)
        button.addTarget(self, action: #selector(deleteAttachment), for: .touchUpInside)
        return button
    }()

    open var attachment: AttachmentManager.Attachment?

    open var indexPath: IndexPath?

    open weak var manager: AttachmentManager?

    private var containerViewLayoutSet: NSLayoutConstraintSet?

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
        indexPath = nil
        manager = nil
        attachment = nil
    }

    // MARK: - Setup

    private func setup() {

        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {

        contentView.addSubview(containerView)
        contentView.addSubview(deleteButton)
    }

    private func setupConstraints() {

        containerViewLayoutSet = NSLayoutConstraintSet(
            top: containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding.top),
            bottom: containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding.bottom),
            left: containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: padding.left),
            right: containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -padding.right)
        ).activate()
        deleteButton.addConstraints(contentView.topAnchor, right: contentView.rightAnchor, widthConstant: 20, heightConstant: 20)
    }

    private func updateContainerPadding() {

        containerViewLayoutSet?.top?.constant = padding.top
        containerViewLayoutSet?.bottom?.constant = -padding.bottom
        containerViewLayoutSet?.left?.constant = padding.left
        containerViewLayoutSet?.right?.constant = -padding.right
    }

    // MARK: - User Actions

    @objc
    func deleteAttachment() {

        guard let index = indexPath?.row else { return }
        manager?.removeAttachment(at: index)
    }
}
