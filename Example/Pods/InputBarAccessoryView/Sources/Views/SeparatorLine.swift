//
// ChatLayout
// SeparatorLine.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/**
 A UIView thats intrinsicContentSize is overrided so an exact height can be specified

 ## Important Notes ##
 1. Default height is 1 pixel
 2. Default backgroundColor is UIColor.lightGray
 3. Intended to be used in an `InputStackView`
 */
open class SeparatorLine: UIView {

    // MARK: - Properties

    /// The height of the line
    open var height: CGFloat = 1.0 / UIScreen.main.scale {
        didSet {
            constraints.filter { $0.identifier == "height" }.forEach { $0.constant = height } // Assumes constraint was given an identifier
            invalidateIntrinsicContentSize()
        }
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width, height: height)
    }

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    /// Sets up the default properties
    open func setup() {
        if #available(iOS 13, *) {
            backgroundColor = .systemGray
        } else {
            backgroundColor = .lightGray
        }
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
}
