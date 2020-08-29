//
// ChatLayout
// TextMessageController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

final class TextMessageController {

    weak var view: TextMessageView? {
        didSet {
            view?.reloadData()
        }
    }

    let text: String

    let type: MessageType

    private let bubbleController: BubbleController

    init(text: String, type: MessageType, bubbleController: BubbleController) {
        self.text = text
        self.type = type
        self.bubbleController = bubbleController
    }

}
