//
// ChatLayout
// UIView+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
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

extension NSUIView {
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

extension NSUIViewController {
    /// https://github.com/ekazaev/route-composer can do it better
    func topMostViewController() -> NSUIViewController {
        if presentedViewController == nil {
            return self
        }
        #if canImport(UIKit)

        if let navigationViewController = presentedViewController as? UINavigationController {
            if let visibleViewController = navigationViewController.visibleViewController {
                return visibleViewController.topMostViewController()
            } else {
                return navigationViewController
            }
        }
        if let tabBarViewController = presentedViewController as? UITabBarController {
            if let selectedViewController = tabBarViewController.selectedViewController {
                return selectedViewController.topMostViewController()
            }
            return tabBarViewController.topMostViewController()
        }

        #endif
        return presentedViewController!.topMostViewController()
    }
}

extension NSUIApplication {
    func topMostViewController() -> NSUIViewController? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return NSApplication.shared.windows.filter(\.isKeyWindow).first?.contentViewController?.topMostViewController()
        #endif

        #if canImport(UIKit)
        return UIApplication.shared.windows.filter(\.isKeyWindow).first?.rootViewController?.topMostViewController()
        #endif
    }
}
