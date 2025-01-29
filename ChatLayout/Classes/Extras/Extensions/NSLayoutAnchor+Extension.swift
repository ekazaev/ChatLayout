//
// ChatLayout
// NSLayoutAnchor+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

extension NSLayoutAnchor {
    @objc func constraint(equalTo anchor: NSLayoutAnchor<AnchorType>,
                          constant c: CGFloat = 0,
                          priority: NSUILayoutPriority) -> NSLayoutConstraint {

        let constraint = constraint(equalTo: anchor, constant: c)
        constraint.priority = priority
        return constraint
    }

    @objc func constraint(greaterThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>,
                          constant c: CGFloat = 0,
                          priority: NSUILayoutPriority) -> NSLayoutConstraint {

        let constraint = constraint(greaterThanOrEqualTo: anchor, constant: c)
        constraint.priority = priority
        return constraint
    }

    @objc func constraint(lessThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>,
                          constant c: CGFloat = 0,
                          priority: NSUILayoutPriority) -> NSLayoutConstraint {

        let constraint = constraint(lessThanOrEqualTo: anchor, constant: c)
        constraint.priority = priority
        return constraint
    }
}

