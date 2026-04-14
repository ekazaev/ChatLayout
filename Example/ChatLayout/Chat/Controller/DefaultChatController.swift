//
// ChatLayout
// DefaultChatController.swift
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

private final class SerialTaskQueue {
    private let continuation: AsyncStream<@Sendable () async -> Void>.Continuation

    private let workerTask: Task<Void, Never>

    init(priority: TaskPriority? = .userInitiated) {
        var createdContinuation: AsyncStream<@Sendable () async -> Void>.Continuation?
        let stream = AsyncStream<@Sendable () async -> Void> { continuation in
            createdContinuation = continuation
        }
        guard let createdContinuation else {
            preconditionFailure("Failed to create serial task queue continuation")
        }
        continuation = createdContinuation
        workerTask = Task(priority: priority) {
            for await operation in stream {
                guard !Task.isCancelled else {
                    break
                }
                await operation()
            }
        }
    }

    func enqueue(_ operation: @escaping @Sendable () async -> Void) {
        continuation.yield(operation)
    }

    deinit {
        continuation.finish()
        workerTask.cancel()
    }
}

final class DefaultChatController: ChatController {
    weak var delegate: ChatControllerDelegate?

    private let dataProvider: RandomDataProvider

    private var typingState: TypingState = .idle

    private let processingQueue = SerialTaskQueue(priority: .userInitiated)

    private var lastReadUUID: UUID?

    private var lastReceivedUUID: UUID?

    private let userId: Int

    private let agentQuestions = [
        "Why does the moon look larger near the horizon?",
        "How do airplanes stay stable in turbulence?",
        "Why do some metals rust while others do not?",
        "How does a search engine rank results so quickly?",
        "Why do people hear an echo in some spaces but not others?",
        "How does a battery store and release energy?",
        "Why does hot water sometimes freeze faster than cold water?",
        "How do noise-cancelling headphones remove background sound?",
        "Why do leaves change color before they fall?",
        "How does a GPS device know where it is?"
    ]

    private(set) var isAgentModeEnabled = false

    private(set) var extendedLayoutMessageID: UUID?

    var messages: [RawMessage] = []

    init(dataProvider: RandomDataProvider, userId: Int) {
        self.dataProvider = dataProvider
        self.userId = userId
    }

    func loadInitialMessages(completion: @escaping @MainActor @Sendable ([Section]) -> Void) {
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

    func loadPreviousMessages(completion: @escaping @MainActor @Sendable ([Section]) -> Void) {
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

    func sendMessage(_ data: Message.Data, completion: @escaping @MainActor @Sendable ([Section]) -> Void) {
        messages.append(RawMessage(id: UUID(), date: Date(), data: convert(data), userId: userId))
        propagateLatestMessages { sections in
            completion(sections)
        }
    }

    func setAgentModeEnabled(_ isEnabled: Bool) {
        guard isAgentModeEnabled != isEnabled else {
            return
        }

        if isEnabled {
            startAgentMode()
        } else {
            finishAgentMode(notifyDataProvider: true)
        }
    }

    func startAgentResponse() {
        guard isAgentModeEnabled else {
            return
        }
        dataProvider.startAgentResponse()
    }

    private func appendConvertingToMessages(_ rawMessages: [RawMessage]) {
        var messages = messages
        messages.append(contentsOf: rawMessages)
        self.messages = messages.sorted(by: { $0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970 })
    }

    private func propagateLatestMessages(completion: @escaping @MainActor @Sendable ([Section]) -> Void) {
        let messages = messages
        let typingState = typingState
        let userId = userId

        processingQueue.enqueue {
            let messagesSplitByDay = messages
                .map { rawMessage in
                    let data: Message.Data
                    switch rawMessage.data {
                    case let .url(url):
                        data = .url(url, isLocallyStored: metadataCache.isEntityCached(for: url))
                    case let .image(source):
                        let isLocallyStored: Bool
                        switch source {
                        case .image:
                            isLocallyStored = true
                        case let .imageURL(url):
                            isLocallyStored = imageCache.isEntityCached(for: CacheableImageKey(url: url))
                        }
                        data = .image(source, isLocallyStored: isLocallyStored)
                    case let .text(text):
                        data = .text(text)
                    }

                    return Message(
                        id: rawMessage.id,
                        date: rawMessage.date,
                        data: data,
                        owner: User(id: rawMessage.userId),
                        type: rawMessage.userId == userId ? .outgoing : .incoming,
                        status: rawMessage.status
                    )
                }
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

            var lastMessageStorage: Message?
            var cells: [Cell] = []

            for (messageGroupIndex, messageGroup) in messagesSplitByDay.enumerated() {
                if let firstMessage = messageGroup.first {
                    cells.append(.date(DateGroup(id: firstMessage.id, date: firstMessage.date)))
                }

                for (messageIndex, message) in messageGroup.enumerated() {
                    let bubble: Cell.BubbleType
                    if messageIndex < messageGroup.count - 1 {
                        let nextMessage = messageGroup[messageIndex + 1]
                        bubble = nextMessage.owner == message.owner ? .normal : .tailed
                    } else {
                        bubble = .tailed
                    }

                    guard message.type != .outgoing else {
                        lastMessageStorage = message
                        cells.append(.message(message, bubbleType: bubble))
                        continue
                    }

                    let titleCell = Cell.messageGroup(MessageGroup(id: message.id, title: "\(message.owner.name)", type: message.type))
                    let shouldInsertTitle = lastMessageStorage.map { $0.owner != message.owner } ?? true
                    if shouldInsertTitle {
                        cells.append(titleCell)
                    }
                    cells.append(.message(message, bubbleType: bubble))
                    lastMessageStorage = message
                }

                if typingState == .typing,
                   messageGroupIndex == messagesSplitByDay.count - 1 {
                    cells.append(.typingIndicator)
                }
            }

            let sections = [Section(id: 0, title: "Loading...", cells: cells)]
            await completion(sections)
        }
    }

    private func convert(_ data: Message.Data) -> RawMessage.Data {
        switch data {
        case let .url(url, isLocallyStored: _):
            .url(url)
        case let .image(source, isLocallyStored: _):
            .image(source)
        case let .text(text):
            .text(text)
        }
    }

    @MainActor
    private func repopulateMessages(requiresIsolatedProcess: Bool = false) {
        propagateLatestMessages { sections in
            self.delegate?.update(with: sections, requiresIsolatedProcess: requiresIsolatedProcess)
        }
    }

    @MainActor
    private func startAgentMode() {
        isAgentModeEnabled = true
        typingState = .idle

        let questionMessage = RawMessage(
            id: UUID(),
            date: Date(),
            data: .text("Question: \(randomQuestion())"),
            userId: userId
        )
        messages.append(questionMessage)
        extendedLayoutMessageID = questionMessage.id
        dataProvider.setAgentModeEnabled(true)
        delegate?.agentModeChanged(to: true)

        propagateLatestMessages { sections in
            self.delegate?.update(with: sections, requiresIsolatedProcess: false)
        }
    }

    @MainActor
    private func finishAgentMode(notifyDataProvider: Bool) {
        let shouldNotifyDelegate = isAgentModeEnabled || extendedLayoutMessageID != nil
        isAgentModeEnabled = false
        extendedLayoutMessageID = nil
        typingState = .idle

        if shouldNotifyDelegate {
            delegate?.agentModeChanged(to: false)
            repopulateMessages()
        }

        if notifyDataProvider {
            dataProvider.setAgentModeEnabled(false)
        }
    }

    private func replaceMessage(_ message: RawMessage) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        messages[index] = message
    }

    private func randomQuestion() -> String {
        agentQuestions.randomElement() ?? "How does this chat layout keep content pinned so reliably?"
    }
}

extension DefaultChatController: RandomDataProviderDelegate {
    func received(messages: [RawMessage]) {
        appendConvertingToMessages(messages)
        markAllMessagesAsReceived {
            self.markAllMessagesAsRead {
                self.repopulateMessages()
            }
        }
    }

    func typingStateChanged(to state: TypingState) {
        typingState = state
        repopulateMessages()
    }

    func updated(message: RawMessage) {
        replaceMessage(message)
        repopulateMessages()
    }

    func lastReadIdChanged(to id: UUID) {
        lastReadUUID = id
        markAllMessagesAsRead {
            self.repopulateMessages()
        }
    }

    func lastReceivedIdChanged(to id: UUID) {
        lastReceivedUUID = id
        markAllMessagesAsReceived {
            self.repopulateMessages()
        }
    }

    func agentDidFinish() {
        finishAgentMode(notifyDataProvider: false)
    }

    func markAllMessagesAsReceived(completion: @escaping @MainActor @Sendable () -> Void) {
        guard let lastReceivedUUID else {
            completion()
            return
        }

        let messages = messages
        let applyUpdatedMessages: @MainActor @Sendable ([RawMessage]) -> Void = { [weak self] updatedMessages in
            self?.messages = updatedMessages
            completion()
        }

        processingQueue.enqueue {
            var finished = false
            let updatedMessages = messages.map { message in
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
            await applyUpdatedMessages(updatedMessages)
        }
    }

    func markAllMessagesAsRead(completion: @escaping @MainActor @Sendable () -> Void) {
        guard let lastReadUUID else {
            completion()
            return
        }

        let messages = messages
        let applyUpdatedMessages: @MainActor @Sendable ([RawMessage]) -> Void = { [weak self] updatedMessages in
            self?.messages = updatedMessages
            completion()
        }

        processingQueue.enqueue {
            var finished = false
            let updatedMessages = messages.map { message in
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
            await applyUpdatedMessages(updatedMessages)
        }
    }
}

@MainActor
extension DefaultChatController: ReloadDelegate {
    func reloadMessage(with id: UUID) {
        repopulateMessages()
    }
}

@MainActor
extension DefaultChatController: EditingAccessoryControllerDelegate {
    func deleteMessage(with id: UUID) {
        if extendedLayoutMessageID == id {
            extendedLayoutMessageID = nil
        }
        messages = Array(messages.filter { $0.id != id })
        repopulateMessages(requiresIsolatedProcess: true)
    }
}
