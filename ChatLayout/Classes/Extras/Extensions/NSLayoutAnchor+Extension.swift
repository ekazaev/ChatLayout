//
// ChatLayout
// NSLayoutAnchor+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

extension NSLayoutAnchor {
    @objc
    func constraint(
        equalTo anchor: NSLayoutAnchor<AnchorType>,
        constant: CGFloat = 0,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(equalTo: anchor, constant: constant)
        constraint.priority = priority
        return constraint
    }

    @objc
    func constraint(
        greaterThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>,
        constant: CGFloat = 0,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(greaterThanOrEqualTo: anchor, constant: constant)
        constraint.priority = priority
        return constraint
    }

    @objc
    func constraint(
        lessThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>,
        constant: CGFloat = 0,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(lessThanOrEqualTo: anchor, constant: constant)
        constraint.priority = priority
        return constraint
    }
}
