//
// ChatLayout
// FullCellContentBubbleController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
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
        guard let bubbleView = bubbleView else {
            return
        }

        UIView.performWithoutAnimation {
            bubbleView.backgroundColor = .clear
            bubbleView.customView.layoutMargins = .zero
        }
    }

}
