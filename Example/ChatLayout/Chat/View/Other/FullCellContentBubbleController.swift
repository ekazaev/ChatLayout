//
// ChatLayout
// FullCellContentBubbleController.swift
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
import UIKit

final class FullCellContentBubbleController<CustomView: UIView>: BubbleController {
    weak var bubbleView: BezierMaskedView<CustomView>? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: BezierMaskedView<CustomView>) {
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }

        UIView.performWithoutAnimation {
            bubbleView.backgroundColor = .clear
            bubbleView.customView.layoutMargins = .zero
        }
    }
}
