//
// ChatLayout
// DefaultBubbleController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class DefaultBubbleController<CustomView: UIView>: BubbleController {

    private let controllerProxy: BubbleController

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: ImageMaskedView<CustomView>? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: ImageMaskedView<CustomView>, controllerProxy: BubbleController, type: MessageType, bubbleType: Cell.BubbleType) {
        self.controllerProxy = controllerProxy
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView = bubbleView else {
            return
        }

        bubbleView.maskTransformation = type.isIncoming ? .flippedVertically : .asIs

        let imageName = bubbleType == .normal ? "bubble_full" : "bubble_full_tail"

        let bubbleImage = UIImage(named: imageName)!
        let center = CGPoint(x: bubbleImage.size.width / 2, y: bubbleImage.size.height / 2)
        let capInsets = UIEdgeInsets(top: center.y, left: center.x, bottom: center.y, right: center.x)

        bubbleView.maskingImage = bubbleImage.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
    }

}
