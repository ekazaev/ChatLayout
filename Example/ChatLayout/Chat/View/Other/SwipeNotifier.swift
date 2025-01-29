//
// ChatLayout
// SwipeNotifier.swift
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

public protocol SwipeNotifierDelegate: AnyObject {
    var swipeCompletionRate: CGFloat { get set }

    var accessorySafeAreaInsets: NSUIEdgeInsets { get set }
}

final class SwipeNotifier {
    private var delegates = NSHashTable<AnyObject>.weakObjects()

    private(set) var accessorySafeAreaInsets: NSUIEdgeInsets = .zero

    private(set) var swipeCompletionRate: CGFloat = 0

    func add(delegate: SwipeNotifierDelegate) {
        delegates.add(delegate)
    }

    func setSwipeCompletionRate(_ swipeCompletionRate: CGFloat) {
        self.swipeCompletionRate = swipeCompletionRate
        delegates.allObjects.compactMap { $0 as? SwipeNotifierDelegate }.forEach { $0.swipeCompletionRate = swipeCompletionRate }
    }

    func setAccessoryOffset(_ accessorySafeAreaInsets: NSUIEdgeInsets) {
        self.accessorySafeAreaInsets = accessorySafeAreaInsets
        delegates.allObjects.compactMap { $0 as? SwipeNotifierDelegate }.forEach { $0.accessorySafeAreaInsets = accessorySafeAreaInsets }
    }
}
