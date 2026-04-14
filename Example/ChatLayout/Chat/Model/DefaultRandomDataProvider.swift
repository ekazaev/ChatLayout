//
// ChatLayout
// DefaultRandomDataProvider.swift
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
protocol RandomDataProviderDelegate: AnyObject {
    func received(messages: [RawMessage])

    func updated(message: RawMessage)

    func typingStateChanged(to state: TypingState)

    func lastReadIdChanged(to id: UUID)

    func lastReceivedIdChanged(to id: UUID)

    func agentDidFinish()
}

@MainActor
protocol RandomDataProvider {
    func loadInitialMessages(completion: @escaping ([RawMessage]) -> Void)

    func loadPreviousMessages(completion: @escaping ([RawMessage]) -> Void)

    func setAgentModeEnabled(_ isEnabled: Bool)

    func startAgentResponse()

    func stop()
}

@MainActor
final class DefaultRandomDataProvider: RandomDataProvider {
    weak var delegate: RandomDataProviderDelegate?

    private var messageTimer: Timer?

    private var typingTimer: Timer?

    private var agentMessageTimer: Timer?

    private var startingTimestamp = Date().timeIntervalSince1970

    private var typingState: TypingState = .idle

    private let users: [Int]

    private let receiverId: Int

    private var lastMessageIndex: Int = 0

    private var lastReadUUID: UUID?

    private var lastReceivedUUID: UUID?

    private let enableTyping = true

    private let enableNewMessages = true

    private let enableRichContent = true

    private var isAgentModeEnabled = false

    private var agentAnswerMessage: RawMessage?

    private let maxAgentAnswerLetterCount = 5000

    private let agentInitialResponseDelay: TimeInterval = 0.35

    private let agentMessageUpdateInterval: TimeInterval = 0.12

    private let websiteUrls: [URL] = [
        URL(string: "https://messagekit.github.io")!,
        URL(string: "https://www.youtube.com/watch?v=GEZhD3J89ZE"),
        URL(string: "https://www.raywenderlich.com/7565482-visually-rich-links-tutorial-for-ios-image-thumbnails"),
        URL(string: "https://github.com/ekazaev/route-composer"),
        URL(string: "https://www.youtube.com/watch?v=-rAeqN-Q7x4"),
        URL(string: "https://en.wikipedia.org/wiki/Dublin"),
        URL(string: "https://en.wikipedia.org/wiki/Republic_of_Ireland"),
        URL(string: "https://en.wikipedia.org/wiki/Cork_(city)"),
        URL(string: "https://github.com/ekazaev/ChatLayout"),
        URL(string: "https://websummit.com")
    ].compactMap { $0 }

    private let imageUrls: [URL] = [
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/a/a4/General_Post_Office_Dublin_20060803.jpg")!,
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/42/Samuel_Beckett_Bridge_At_Sunset_Dublin_Ireland_%2897037639%29_%28cropped%29.jpeg")!,
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/f/f2/Cork_river_lee.jpg")!,
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/97/Fountain_Galway_01.jpg")!,
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Limerick-King-Johns-Castle-2012.JPG/1920px-Limerick-King-Johns-Castle-2012.JPG")!
    ]

    private let images: [UIImage] = (1...8).compactMap { UIImage(named: "demo\($0)") }

    private var allUsersIds: [Int] {
        Array([users, [receiverId]].joined())
    }

    init(receiverId: Int, usersIds: [Int]) {
        users = usersIds
        self.receiverId = receiverId
    }

    func loadInitialMessages(completion: @escaping ([RawMessage]) -> Void) {
        resumeDefaultTimersIfNeeded()
        let messages = createBunchOfMessages(number: 50)
        if messages.count > 10 {
            lastReceivedUUID = messages[messages.count - 10].id
        }
        if messages.count > 3 {
            lastReadUUID = messages[messages.count - 3].id
        }
        completion(messages)
    }

    func loadPreviousMessages(completion: @escaping ([RawMessage]) -> Void) {
        completion(createBunchOfMessages(number: 50))
    }

    func stop() {
        isAgentModeEnabled = false
        agentAnswerMessage = nil
        stopDefaultTimers()
        stopAgentTimer()
    }

    func setAgentModeEnabled(_ isEnabled: Bool) {
        guard isAgentModeEnabled != isEnabled else {
            return
        }

        isAgentModeEnabled = isEnabled
        let previousTypingState = typingState
        typingState = .idle
        if previousTypingState != .idle {
            delegate?.typingStateChanged(to: .idle)
        }

        if isEnabled {
            stopDefaultTimers()
        } else {
            agentAnswerMessage = nil
            stopAgentTimer()
            resumeDefaultTimersIfNeeded()
        }
    }

    func startAgentResponse() {
        guard isAgentModeEnabled,
              agentAnswerMessage == nil else {
            return
        }
        startAgentConversation()
    }

    @objc
    private func handleTimer() {
        guard enableNewMessages,
              !isAgentModeEnabled else {
            return
        }
        let message = createRandomMessage()
        delegate?.received(messages: [message])

        if message.userId != receiverId {
            if Int.random(in: 0...1) == 0 {
                lastReceivedUUID = message.id
                delegate?.lastReceivedIdChanged(to: message.id)
            }
            if Int.random(in: 0...3) == 0 {
                lastReadUUID = lastReceivedUUID
                lastReceivedUUID = message.id
                delegate?.lastReadIdChanged(to: message.id)
            }
        }

        restartMessageTimer()
        restartTypingTimer()
    }

    @objc
    private func handleTypingTimer() {
        guard enableTyping,
              !isAgentModeEnabled else {
            return
        }
        typingState = typingState == .idle ? TypingState.typing : .idle
        delegate?.typingStateChanged(to: typingState)
    }

    @objc
    private func handleAgentMessageTimer() {
        guard isAgentModeEnabled,
              var answerMessage = agentAnswerMessage,
              case let .text(currentText) = answerMessage.data else {
            return
        }

        let updatedText = currentText + " " + randomAgentAnswerFragment()
        answerMessage.data = .text(updatedText)
        agentAnswerMessage = answerMessage
        delegate?.updated(message: answerMessage)

        if letterCount(in: updatedText) >= maxAgentAnswerLetterCount {
            finishAgentMode()
        }
    }

    private func restartMessageTimer() {
        guard !isAgentModeEnabled else {
            return
        }
        messageTimer?.invalidate()
        messageTimer = nil
        messageTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Int.random(in: 0...6)), target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
    }

    private func restartTypingTimer() {
        guard !isAgentModeEnabled else {
            return
        }
        typingTimer?.invalidate()
        typingTimer = nil
        typingTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Int.random(in: 1...3)), target: self, selector: #selector(handleTypingTimer), userInfo: nil, repeats: true)
    }

    private func restartAgentMessageTimer(initialDelay: TimeInterval = 0) {
        guard isAgentModeEnabled else {
            return
        }
        agentMessageTimer?.invalidate()
        agentMessageTimer = nil
        if initialDelay > 0 {
            agentMessageTimer = Timer.scheduledTimer(timeInterval: initialDelay, target: self, selector: #selector(handleInitialAgentMessageTimer), userInfo: nil, repeats: false)
        } else {
            agentMessageTimer = Timer.scheduledTimer(timeInterval: agentMessageUpdateInterval, target: self, selector: #selector(handleAgentMessageTimer), userInfo: nil, repeats: true)
        }
    }

    @objc
    private func handleInitialAgentMessageTimer() {
        restartAgentMessageTimer()
    }

    private func stopDefaultTimers() {
        messageTimer?.invalidate()
        messageTimer = nil
        typingTimer?.invalidate()
        typingTimer = nil
    }

    private func stopAgentTimer() {
        agentMessageTimer?.invalidate()
        agentMessageTimer = nil
    }

    private func resumeDefaultTimersIfNeeded() {
        guard !isAgentModeEnabled else {
            return
        }
        restartMessageTimer()
        restartTypingTimer()
    }

    private func startAgentConversation() {
        stopAgentTimer()

        let answerMessage = RawMessage(
            id: UUID(),
            date: Date().addingTimeInterval(0.001),
            data: .text("Answer"),
            userId: users.randomElement() ?? receiverId
        )
        agentAnswerMessage = answerMessage
        delegate?.received(messages: [answerMessage])
        restartAgentMessageTimer(initialDelay: agentInitialResponseDelay)
    }

    private func finishAgentMode() {
        isAgentModeEnabled = false
        agentAnswerMessage = nil
        stopAgentTimer()
        resumeDefaultTimersIfNeeded()
        delegate?.agentDidFinish()
    }

    private func randomAgentAnswerFragment() -> String {
        let sentence = TextGenerator.getString(of: Int.random(in: 4...10))
        let trimmedSentence = sentence.hasSuffix(".") ? String(sentence.dropLast()) : sentence
        guard let firstCharacter = trimmedSentence.first else {
            return trimmedSentence
        }
        return String(firstCharacter).lowercased() + trimmedSentence.dropFirst()
    }

    private func letterCount(in text: String) -> Int {
        text.unicodeScalars.filter(CharacterSet.letters.contains).count
    }

    private func createRandomMessage(date: Date = Date()) -> RawMessage {
        let sender = allUsersIds[Int.random(in: 0..<allUsersIds.count)] // allUsersIds.first!//
        lastMessageIndex += 1
        switch (Int.random(in: 0...8), enableRichContent) {
        case (5, true):
            return RawMessage(id: UUID(), date: date, data: .url(websiteUrls[Int.random(in: 0..<websiteUrls.count)]), userId: sender)
        case (6, true):
            return RawMessage(id: UUID(), date: date, data: .image(.imageURL(imageUrls[Int.random(in: 0..<imageUrls.count)])), userId: sender)
        case (7, true):
            return RawMessage(id: UUID(), date: date, data: .image(.image(images[Int.random(in: 0..<images.count)])), userId: sender)
        case (8, true):
            return RawMessage(
                id: UUID(),
                date: date,
                data: .text(
                    TextGenerator.getString(of: 5) +
                        " \(websiteUrls[Int.random(in: 0..<websiteUrls.count)]). " +
                        TextGenerator.getString(of: 5)
                ),
                userId: sender
            )
        default:
            return RawMessage(id: UUID(), date: date, data: .text(TextGenerator.getString(of: 20)), userId: sender)
        }
    }

    private func createBunchOfMessages(number: Int = 50) -> [RawMessage] {
        let messages = (0..<number).map { _ -> RawMessage in
            startingTimestamp -= TimeInterval(Int.random(in: 100...1000))
            return self.createRandomMessage(date: Date(timeIntervalSince1970: startingTimestamp))
        }
        return messages
    }
}
