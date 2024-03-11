//
// ChatLayout
// SwipeNotifier.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

public protocol SwipeNotifierDelegate: AnyObject {
    var swipeCompletionRate: CGFloat { get set }

    var accessorySafeAreaInsets: UIEdgeInsets { get set }
}

final class SwipeNotifier {
    private var delegates = NSHashTable<AnyObject>.weakObjects()

    private(set) var accessorySafeAreaInsets: UIEdgeInsets = .zero

    private(set) var swipeCompletionRate: CGFloat = 0

    func add(delegate: SwipeNotifierDelegate) {
        delegates.add(delegate)
    }

    func setSwipeCompletionRate(_ swipeCompletionRate: CGFloat) {
        self.swipeCompletionRate = swipeCompletionRate
        delegates.allObjects.compactMap { $0 as? SwipeNotifierDelegate }.forEach { $0.swipeCompletionRate = swipeCompletionRate }
    }

    func setAccessoryOffset(_ accessorySafeAreaInsets: UIEdgeInsets) {
        self.accessorySafeAreaInsets = accessorySafeAreaInsets
        delegates.allObjects.compactMap { $0 as? SwipeNotifierDelegate }.forEach { $0.accessorySafeAreaInsets = accessorySafeAreaInsets }
    }
}
