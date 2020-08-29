//
// ChatLayout
// FullCellContentBubbleController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

final class FullCellContentBubbleController<CustomView: UIView>: BubbleController {

    weak var bubbleView: ImageMaskedView<CustomView>? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: ImageMaskedView<CustomView>) {
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView = bubbleView else {
            return
        }

        bubbleView.backgroundColor = .clear
        bubbleView.customView.layoutMargins = .zero
    }

}
