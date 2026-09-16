//
// ChatLayout
// Cell.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
import UIKit

enum Cell: Hashable {
    // swiftlint:disable:next type_name
    enum ID: Hashable {
        case message(UUID)
        case typingIndicator
        case messageGroup(UUID)
        case date(UUID)
    }

    enum BubbleType {
        case normal
        case tailed
    }

    case message(Message, bubbleType: BubbleType)

    case typingIndicator

    case messageGroup(MessageGroup)

    case date(DateGroup)

    var id: ID {
        switch self {
        case let .message(message, _):
            .message(message.id)
        case .typingIndicator:
            .typingIndicator
        case let .messageGroup(group):
            .messageGroup(group.id)
        case let .date(group):
            .date(group.id)
        }
    }

    var alignment: ChatItemAlignment {
        switch self {
        case let .message(message, _):
            message.type == .incoming ? .leading : .trailing
        case .typingIndicator:
            .leading
        case let .messageGroup(group):
            group.type == .incoming ? .leading : .trailing
        case .date:
            .center
        }
    }
}
