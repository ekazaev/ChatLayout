//
// ChatLayout
// Message.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import DifferenceKit
import Foundation

enum MessageType: Hashable {

    case incoming

    case outgoing

    var isIncoming: Bool {
        return self == .incoming
    }

}

enum MessageStatus: Hashable {

    case sent

    case received

    case read

}

extension ChatItemAlignment {

    var isIncoming: Bool {
        return self == .leading
    }

}

struct DateGroup: Hashable {

    var id: UUID

    var date: Date

    var value: String {
        return ChatDateFormatter.shared.string(from: date)
    }

    init(id: UUID, date: Date) {
        self.id = id
        self.date = date
    }

}

extension DateGroup: Differentiable {

    public var differenceIdentifier: Int {
        return hashValue
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
        return hashValue
    }

    public func isContentEqual(to source: MessageGroup) -> Bool {
        self == source
    }

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

extension Message: Differentiable {

    public var differenceIdentifier: Int {
        return id.hashValue
    }

    public func isContentEqual(to source: Message) -> Bool {
        return self == source
    }

}
