//
// ChatLayout
// EditingAccessoryController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

@MainActor
protocol EditingAccessoryControllerDelegate: AnyObject {
    func deleteMessage(with id: UUID)
}

@MainActor
final class EditingAccessoryController {
    weak var delegate: EditingAccessoryControllerDelegate?

    weak var view: EditingAccessoryView?

    private let messageID: UUID

    init(messageID: UUID) {
        self.messageID = messageID
    }

    func deleteButtonTapped() {
        delegate?.deleteMessage(with: messageID)
    }
}
