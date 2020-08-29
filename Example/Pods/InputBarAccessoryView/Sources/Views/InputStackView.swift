//
// ChatLayout
// InputStackView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/**
 A UIStackView that's intended for holding `InputItem`s

 ## Important Notes ##
 1. Default alignment is .fill
 2. Default distribution is .fill
 3. The distribution property needs to be based on its arranged subviews intrinsicContentSize so it is not recommended to change it
 */
open class InputStackView: UIStackView {

    /// The stack view position in the InputBarAccessoryView
    ///
    /// - left: Left Stack View
    /// - right: Bottom Stack View
    /// - bottom: Left Stack View
    /// - top: Top Stack View
    public enum Position {
        case left, right, bottom, top
    }

    // MARK: Initialization

    convenience init(axis: NSLayoutConstraint.Axis, spacing: CGFloat) {
        self.init(frame: .zero)
        self.axis = axis
        self.spacing = spacing
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Setup

    /// Sets up the default properties
    open func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        distribution = .fill
        alignment = .bottom
    }

}
