//
// ChatLayout
// NSLayoutDimension+Extension.swift
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

extension NSLayoutDimension {
    @objc
    func constraint(
        equalTo anchor: NSLayoutDimension,
        multiplier m: CGFloat = 1,
        constant: CGFloat = 0,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(equalTo: anchor, multiplier: m, constant: constant)
        constraint.priority = priority
        return constraint
    }

    @objc
    func constraint(
        greaterThanOrEqualTo anchor: NSLayoutDimension,
        multiplier: CGFloat = 1,
        constant: CGFloat = 0,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(greaterThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
        constraint.priority = priority
        return constraint
    }

    @objc
    func constraint(
        lessThanOrEqualTo anchor: NSLayoutDimension,
        multiplier: CGFloat = 1,
        constant: CGFloat = 0,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(lessThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
        constraint.priority = priority
        return constraint
    }

    @objc
    func constraint(
        equalToConstant constant: CGFloat,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(equalToConstant: constant)
        constraint.priority = priority
        return constraint
    }

    @objc
    func constraint(
        greaterThanOrEqualToConstant constant: CGFloat,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(greaterThanOrEqualToConstant: constant)
        constraint.priority = priority
        return constraint
    }

    @objc
    func constraint(
        lessThanOrEqualToConstant constant: CGFloat,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {
        let constraint = constraint(lessThanOrEqualToConstant: constant)
        constraint.priority = priority
        return constraint
    }
}
