//
// ChatLayout
// DefaultChatController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation

final class DefaultChatController: ChatController {

    weak var delegate: ChatControllerDelegate?

    private let dataProvider: RandomDataProvider

    private var typingState: TypingState = .idle

    private let dispatchQueue = DispatchQueue(label: "DefaultChatController", qos: .userInteractive)

    private var lastReadUUID: UUID?

    private var lastReceivedUUID: UUID?

    private let userId: Int

    var messages: [RawMessage] = []

    init(dataProvider: RandomDataProvider, userId: Int) {
        self.dataProvider = dataProvider
        self.userId = userId
    }

    func loadInitialMessages(completion: @escaping ([Section]) -> Void) {
        dataProvider.loadInitialMessages { messages in
            self.appendConvertingToMessages(messages)
            self.markAllMessagesAsReceived {
                self.markAllMessagesAsRead {
                    self.propagateLatestMessages { sections in
                        completion(sections)
                    }
                }
            }
        }
    }

    func loadPreviousMessages(completion: @escaping ([Section]) -> Void) {
        dataProvider.loadPreviousMessages(completion: { messages in
            self.appendConvertingToMessages(messages)
            self.markAllMessagesAsReceived {
                self.markAllMessagesAsRead {
                    self.propagateLatestMessages { sections in
                        completion(sections)
                    }
                }
            }
        })
    }

    func sendMessage(_ data: Message.Data, completion: @escaping ([Section]) -> Void) {
        messages.append(RawMessage(id: UUID(), date: Date(), data: convert(data), userId: userId))
        propagateLatestMessages { sections in
            completion(sections)
        }
    }

    private func appendConvertingToMessages(_ rawMessages: [RawMessage]) {
        var messages = self.messages
        messages.append(contentsOf: rawMessages)
        self.messages = messages.sorted(by: { $0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970 })
    }

    private func propagateLatestMessages(completion: @escaping ([Section]) -> Void) {
        var lastMessageStorage: Message?
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            let messagesSplitByDay = self.messages
                .map { Message(id: $0.id, date: $0.date, data: self.convert($0.data), owner: User(id: $0.userId), type: $0.userId == self.userId ? .outgoing : .incoming, status: $0.status) }
                .reduce(into: [[Message]]()) { result, message in
                    guard var section = result.last,
                        let prevMessage = section.last else {
                        let section = [message]
                        result.append(section)
                        return
                    }
                    if Calendar.current.isDate(prevMessage.date, equalTo: message.date, toGranularity: .hour) {
                        section.append(message)
                        result[result.count - 1] = section
                    } else {
                        let section = [message]
                        result.append(section)
                    }
                }

            let cells = messagesSplitByDay.enumerated().map { index, messages -> [Cell] in
                var cells: [Cell] = Array(messages.enumerated().map { index, message -> [Cell] in
                    let bubble: Cell.BubbleType
                    if index < messages.count - 1 {
                        let nextMessage = messages[index + 1]
                        bubble = nextMessage.owner == message.owner ? .normal : .tailed
                    } else {
                        bubble = .tailed
                    }
                    guard message.type != .outgoing else {
                        lastMessageStorage = message
                        return [.message(message, bubbleType: bubble)]
                    }

                    let titleCell = Cell.messageGroup(MessageGroup(id: message.id, title: "\(message.owner.name)", type: message.type))

                    if let lastMessage = lastMessageStorage {
                        if lastMessage.owner != message.owner {
                            lastMessageStorage = message
                            return [titleCell, .message(message, bubbleType: bubble)]
                        } else {
                            lastMessageStorage = message
                            return [.message(message, bubbleType: bubble)]
                        }
                    } else {
                        lastMessageStorage = message
                        return [titleCell, .message(message, bubbleType: bubble)]
                    }
                }.joined())

                if let firstMessage = messages.first {
                    let dateCell = Cell.date(DateGroup(id: firstMessage.id, date: firstMessage.date))
                    cells.insert(dateCell, at: 0)
                }

                if self.typingState == .typing,
                    index == messagesSplitByDay.count - 1 {
                    cells.append(.typingIndicator)
                }

                return cells // Section(id: sectionTitle.hashValue, title: sectionTitle, cells: cells)
            }.joined()

            DispatchQueue.main.async { [weak self] in
                guard self != nil else {
                    return
                }
                completion([Section(id: 0, title: "Loading...", cells: Array(cells))])
            }
        }

    }

    private func convert(_ data: Message.Data) -> RawMessage.Data {
        switch data {
        case let .url(url, isLocallyStored: _):
            return .url(url)
        case let .image(source, isLocallyStored: _):
            return .image(source)
        case let .text(text):
            return .text(text)
        }
    }

    private func convert(_ data: RawMessage.Data) -> Message.Data {
        switch data {
        case let .url(url):
            let isLocallyStored: Bool
            if #available(iOS 13, *) {
                isLocallyStored = metadataCache.isEntityCached(for: url)
            } else {
                isLocallyStored = true
            }
            return .url(url, isLocallyStored: isLocallyStored)
        case let .image(source):
            func isPresentLocally(_ source: ImageMessageSource) -> Bool {
                switch source {
                case .image:
                    return true
                case let .imageURL(url):
                    return imageCache.isEntityCached(for: CacheableImageKey(url: url))
                }
            }
            return .image(source, isLocallyStored: isPresentLocally(source))
        case let .text(text):
            return .text(text)
        }
    }

}

extension DefaultChatController: RandomDataProviderDelegate {

    func received(messages: [RawMessage]) {
        appendConvertingToMessages(messages)
        markAllMessagesAsReceived {
            self.markAllMessagesAsRead {
                self.propagateLatestMessages { sections in
                    self.delegate?.update(with: sections)
                }
            }
        }
    }

    func typingStateChanged(to state: TypingState) {
        typingState = state
        propagateLatestMessages { sections in
            self.delegate?.update(with: sections)
        }
    }

    func lastReadIdChanged(to id: UUID) {
        lastReadUUID = id
        markAllMessagesAsRead {
            self.propagateLatestMessages { sections in
                self.delegate?.update(with: sections)
            }
        }
    }

    func lastReceivedIdChanged(to id: UUID) {
        lastReceivedUUID = id
        markAllMessagesAsReceived {
            self.propagateLatestMessages { sections in
                self.delegate?.update(with: sections)
            }
        }
    }

    func markAllMessagesAsReceived(completion: @escaping () -> Void) {
        guard let lastReceivedUUID = lastReceivedUUID else {
            completion()
            return
        }
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            var finished = false
            self.messages = self.messages.map { message in
                guard !finished, message.status != .received, message.status != .read else {
                    if message.id == lastReceivedUUID {
                        finished = true
                    }
                    return message
                }
                var message = message
                message.status = .received
                if message.id == lastReceivedUUID {
                    finished = true
                }
                return message
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func markAllMessagesAsRead(completion: @escaping () -> Void) {
        guard let lastReadUUID = lastReadUUID else {
            completion()
            return
        }
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            var finished = false
            self.messages = self.messages.map { message in
                guard !finished, message.status != .read else {
                    if message.id == lastReadUUID {
                        finished = true
                    }
                    return message
                }
                var message = message
                message.status = .read
                if message.id == lastReadUUID {
                    finished = true
                }
                return message
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

}

extension DefaultChatController: ReloadDelegate {

    func reloadMessage(with id: UUID) {
        propagateLatestMessages(completion: { sections in
            self.delegate?.update(with: sections)
        })
    }

}

extension DefaultChatController: EditingAccessoryControllerDelegate {

    func deleteMessage(with id: UUID) {
        messages = Array(messages.filter { $0.id != id })
        propagateLatestMessages(completion: { sections in
            self.delegate?.update(with: sections)
        })
    }

}
