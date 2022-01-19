//
// ChatLayout
// UIView+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation
import UIKit

extension UIView {

    // Even though we do not set it animated - it can happen during the animated batch update
    // http://www.openradar.me/25087688
    // https://github.com/nkukushkin/StackView-Hiding-With-Animation-Bug-Example
    var isHiddenSafe: Bool {
        get {
            return isHidden
        }
        set {
            guard isHidden != newValue else {
                return
            }
            isHidden = newValue
        }
    }

}

extension UIViewController {
    // https://github.com/ekazaev/route-composer can do it better
    func topMostViewController() -> UIViewController {
        if presentedViewController == nil {
            return self
        }
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
        return presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return UIApplication.shared.windows.filter(\.isKeyWindow).first?.rootViewController?.topMostViewController()
    }
}
