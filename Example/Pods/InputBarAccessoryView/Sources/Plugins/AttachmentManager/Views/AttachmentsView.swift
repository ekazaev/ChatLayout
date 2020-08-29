//
// ChatLayout
// AttachmentsView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

@available(*, deprecated, message: "AttachmentsView has been renamed to AttachmentCollectionView")
public typealias AttachmentsView = AttachmentCollectionView

open class AttachmentCollectionView: UICollectionView {

    // MARK: - Properties

    open var intrinsicContentHeight: CGFloat = 100 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: intrinsicContentHeight)
    }

    // MARK: - Initialization

    public init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.sectionInset.top = 5
        layout.sectionInset.bottom = 5
        layout.headerReferenceSize = CGSize(width: 12, height: 0)
        layout.footerReferenceSize = CGSize(width: 12, height: 0)
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }

    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Setup

    private func setup() {

        backgroundColor = .white
        alwaysBounceHorizontal = true
        showsHorizontalScrollIndicator = true
        setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        register(AttachmentCell.self, forCellWithReuseIdentifier: AttachmentCell.reuseIdentifier)
        register(ImageAttachmentCell.self, forCellWithReuseIdentifier: ImageAttachmentCell.reuseIdentifier)
    }
}
