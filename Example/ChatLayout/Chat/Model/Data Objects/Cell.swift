//
// ChatLayout
// Cell.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import DifferenceKit
import Foundation
import UIKit

enum Cell: Hashable {
    enum BubbleType {
        case normal
        case tailed
    }

    case message(Message, bubbleType: BubbleType)

    case typingIndicator

    case messageGroup(MessageGroup)

    case date(DateGroup)

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

extension Cell: Differentiable {
    public var differenceIdentifier: Int {
        switch self {
        case let .message(message, _):
            message.differenceIdentifier
        case .typingIndicator:
            hashValue
        case let .messageGroup(group):
            group.differenceIdentifier
        case let .date(group):
            group.differenceIdentifier
        }
    }

    public func isContentEqual(to source: Cell) -> Bool {
        self == source
    }
}
