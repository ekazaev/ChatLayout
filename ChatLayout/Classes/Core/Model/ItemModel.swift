//
// ChatLayout
// ItemModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

struct ItemModel {
    struct Configuration {
        let alignment: ChatItemAlignment

        let pinningBehavior: ChatItemPinningBehavior?

        let preferredSize: CGSize

        let calculatedSize: CGSize?

        let interItemSpacing: CGFloat
    }

    let id: UUID

    var preferredSize: CGSize

    var offsetY: CGFloat = .zero

    var calculatedSize: CGSize?

    var calculatedOnce: Bool = false

    var alignment: ChatItemAlignment

    var pinningBehavior: ChatItemPinningBehavior?

    var interItemSpacing: CGFloat

    var size: CGSize {
        guard let calculatedSize else {
            return preferredSize
        }

        return calculatedSize
    }

    var frame: CGRect {
        CGRect(origin: CGPoint(x: 0, y: offsetY), size: size)
    }

    init(id: UUID = UUID(), with configuration: Configuration) {
        self.id = id
        alignment = configuration.alignment
        preferredSize = configuration.preferredSize
        interItemSpacing = configuration.interItemSpacing
        calculatedSize = configuration.calculatedSize
        calculatedOnce = configuration.calculatedSize != nil
        pinningBehavior = configuration.pinningBehavior
    }

    // We are just resetting `calculatedSize` if needed as the actual size will be found in
    // `invalidationContext(forPreferredLayoutAttributes:, withOriginalAttributes:)`.
    // It is important for the rotation to keep previous frame size.
    mutating func resetSize() {
        guard let calculatedSize else {
            return
        }
        self.calculatedSize = nil
        preferredSize = calculatedSize
    }
}
