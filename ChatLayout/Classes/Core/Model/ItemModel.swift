//
// ChatLayout
// ItemModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct ItemModel: Equatable {

    struct Configuration {

        let alignment: ChatItemAlignment

        let preferredSize: CGSize

        let calculatedSize: CGSize?

    }

    let id: UUID

    var preferredSize: CGSize

    var offsetY: CGFloat = .zero

    var calculatedSize: CGSize?

    var calculatedOnce: Bool = false

    var alignment: ChatItemAlignment

    init(id: UUID = UUID(), with configuration: Configuration) {
        self.id = id
        self.alignment = configuration.alignment
        self.preferredSize = configuration.preferredSize
        self.calculatedSize = configuration.calculatedSize
        self.calculatedOnce = configuration.calculatedSize != nil
    }

    var origin: CGPoint {
        return CGPoint(x: 0, y: offsetY)
    }

    var height: CGFloat {
        return size.height
    }

    var locationHeight: CGFloat {
        return offsetY + height
    }

    var size: CGSize {
        guard let calculatedSize = calculatedSize else {
            return preferredSize
        }

        return calculatedSize
    }

    var frame: CGRect {
        return CGRect(origin: origin, size: size)
    }

    // We are just resetting `calculatedSize` if needed as the actual size will be found in invalidationContext(forPreferredLayoutAttributes:, withOriginalAttributes:)
    // It is important for the rotation to keep previous frame size.
    mutating func resetSize() {
        guard let calculatedSize = calculatedSize else {
            return
        }
        self.calculatedSize = nil
        preferredSize = calculatedSize
    }

}
