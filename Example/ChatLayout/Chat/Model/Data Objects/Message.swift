//
// ChatLayout
// Message.swift
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

enum MessageType: Hashable {
    case incoming

    case outgoing

    var isIncoming: Bool {
        self == .incoming
    }
}

enum MessageStatus: Hashable {
    case sent

    case received

    case read
}

extension ChatItemAlignment {
    var isIncoming: Bool {
        self == .leading
    }
}

struct DateGroup: Hashable {
    var id: UUID

    var date: Date

    var value: String {
        ChatDateFormatter.shared.string(from: date)
    }
}

struct MessageGroup: Hashable {
    var id: UUID

    var title: String

    var type: MessageType
}

struct Message: Hashable {
    enum Data: Hashable {
        case text(String)

        case url(URL, isLocallyStored: Bool)

        case image(ImageMessageSource, isLocallyStored: Bool)
    }

    var id: UUID

    var date: Date

    var data: Data

    var owner: User

    var type: MessageType

    var status: MessageStatus = .sent
}
