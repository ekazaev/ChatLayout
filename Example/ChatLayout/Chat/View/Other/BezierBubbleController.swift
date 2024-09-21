//
// ChatLayout
// BezierBubbleController.swift
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

final class BezierBubbleController<CustomView: UIView>: BubbleController {
    private let controllerProxy: BubbleController

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: BezierMaskedView<CustomView>? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: BezierMaskedView<CustomView>, controllerProxy: BubbleController, type: MessageType, bubbleType: Cell.BubbleType) {
        self.controllerProxy = controllerProxy
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }

        bubbleView.messageType = type
        bubbleView.bubbleType = bubbleType
    }
}
