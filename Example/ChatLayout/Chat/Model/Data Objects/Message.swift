//
// ChatLayout
// Message.swift
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

    init(id: UUID, date: Date) {
        self.id = id
        self.date = date
    }
}

extension DateGroup: Differentiable {
    public var differenceIdentifier: Int {
        hashValue
    }

    public func isContentEqual(to source: DateGroup) -> Bool {
        self == source
    }
}

struct MessageGroup: Hashable {
    var id: UUID

    var title: String

    var type: MessageType

    init(id: UUID, title: String, type: MessageType) {
        self.id = id
        self.title = title
        self.type = type
    }
}

extension MessageGroup: Differentiable {
    public var differenceIdentifier: Int {
        hashValue
    }

    public func isContentEqual(to source: MessageGroup) -> Bool {
        self == source
    }
}

struct ReplyInfo {
    let replyUUID: UUID
    let type: MessageType
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

    var replyUUID: UUID

    var replyInfo: ReplyInfo {
        return ReplyInfo(replyUUID: replyUUID, type: type)
    }
}

extension Message: Differentiable {
    public var differenceIdentifier: Int {
        id.hashValue
    }

    public func isContentEqual(to source: Message) -> Bool {
        self == source
    }
}
