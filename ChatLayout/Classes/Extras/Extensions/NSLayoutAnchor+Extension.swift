//
// ChatLayout
// NSLayoutAnchor+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2023.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

extension NSLayoutAnchor {
    @objc func constraint(equalTo anchor: NSLayoutAnchor<AnchorType>,
                          constant c: CGFloat = 0,
                          priority: UILayoutPriority) -> NSLayoutConstraint {
        let constraint = constraint(equalTo: anchor, constant: c)
        constraint.priority = priority
        return constraint
    }

    @objc func constraint(greaterThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>,
                          constant c: CGFloat = 0,
                          priority: UILayoutPriority) -> NSLayoutConstraint {
        let constraint = constraint(greaterThanOrEqualTo: anchor, constant: c)
        constraint.priority = priority
        return constraint
    }

    @objc func constraint(lessThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>,
                          constant c: CGFloat = 0,
                          priority: UILayoutPriority) -> NSLayoutConstraint {
        let constraint = constraint(lessThanOrEqualTo: anchor, constant: c)
        constraint.priority = priority
        return constraint
    }
}
