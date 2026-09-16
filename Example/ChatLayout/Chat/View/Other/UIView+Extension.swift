//
// ChatLayout
// UIView+Extension.swift
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

extension UIView {
    func superview<T>(of type: T.Type) -> T? {
        superview as? T ?? superview.flatMap { $0.superview(of: type) }
    }

    func subview<T>(of type: T.Type) -> T? {
        subviews.compactMap { $0 as? T ?? $0.subview(of: type) }.first
    }

    /// Even though we do not set it animated - it can happen during the animated batch update
    /// http://www.openradar.me/25087688
    /// https://github.com/nkukushkin/StackView-Hiding-With-Animation-Bug-Example
    var isHiddenSafe: Bool {
        get {
            isHidden
        }
        set {
            guard isHidden != newValue else {
                return
            }
            isHidden = newValue
        }
    }
}
