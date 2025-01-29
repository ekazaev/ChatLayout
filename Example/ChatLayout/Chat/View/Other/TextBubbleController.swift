//
// ChatLayout
// TextBubbleController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

final class TextBubbleController<CustomView: NSUIView>: BubbleController {
    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: NSUIView? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: NSUIView, type: MessageType, bubbleType: Cell.BubbleType) {
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }
        NSUIView.performWithoutAnimation {
            let marginOffset: CGFloat = type.isIncoming ? -Constants.tailSize : Constants.tailSize
            let edgeInsets = NSUIEdgeInsets(top: 8, left: 16 - marginOffset, bottom: 8, right: 16 + marginOffset)
            bubbleView.layoutMargins = edgeInsets

            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            bubbleView.backgroundColor = type.isIncoming ? .windowBackgroundColor : .systemBlue
            #endif

            #if canImport(UIKit)
            if #available(iOS 13.0, *) {
                bubbleView.backgroundColor = type.isIncoming ? .systemGray5 : .systemBlue
            } else {
                let systemGray5 = NSUIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
                bubbleView.backgroundColor = type.isIncoming ? systemGray5 : .systemBlue
            }
            #endif
        }
    }
}
