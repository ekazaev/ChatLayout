//
// ChatLayout
// TextBubbleController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class TextBubbleController<CustomView: UIView>: BubbleController {

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: ImageMaskedView<CustomView>? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: ImageMaskedView<CustomView>, type: MessageType, bubbleType: Cell.BubbleType) {
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView = bubbleView else {
            return
        }
        let marginOffset: CGFloat = type.isIncoming ? -Constants.tailSize : Constants.tailSize
        bubbleView.layoutMargins = UIEdgeInsets(top: 8, left: 16 - marginOffset, bottom: 8, right: 16 + marginOffset)

        if #available(iOS 13.0, *) {
            bubbleView.backgroundColor = type.isIncoming ? .systemGray5 : .systemBlue
        } else {
            bubbleView.backgroundColor = type.isIncoming ? UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1) : .systemBlue
        }
    }

}
