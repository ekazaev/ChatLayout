//
// ChatLayout
// DefaultRandomDataProvider.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

protocol RandomDataProviderDelegate: AnyObject {

    func received(messages: [RawMessage])

    func typingStateChanged(to state: TypingState)

    func lastReadIdChanged(to id: UUID)

    func lastReceivedIdChanged(to id: UUID)

}

protocol RandomDataProvider {

    func loadInitialMessages(completion: @escaping ([RawMessage]) -> Void)

    func loadPreviousMessages(completion: @escaping ([RawMessage]) -> Void)

    func stop()

}

final class DefaultRandomDataProvider: RandomDataProvider {

    weak var delegate: RandomDataProviderDelegate?

    private var messageTimer: Timer?

    private var typingTimer: Timer?

    private var startingTimestamp = Date().timeIntervalSince1970

    private var typingState: TypingState = .idle

    private let users: [Int]

    private let receiverId: Int

    private var lastMessageIndex: Int = 0

    private var lastReadUUID: UUID?

    private var lastReceivedUUID: UUID?

    private let dispatchQueue = DispatchQueue.global(qos: .userInteractive)

    private let enableTyping = true

    private let enableNewMessages = true

    private let enableRichContent = true

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
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/O%27Connell_Street_Dublin_%26_Jim_Larkin.JPG/800px-O%27Connell_Street_Dublin_%26_Jim_Larkin.JPG")!,
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/St.Patrick%27s_Bridge.jpg/2560px-St.Patrick%27s_Bridge.jpg")!,
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/97/Fountain_Galway_01.jpg")!,
        URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Limerick-King-Johns-Castle-2012.JPG/1920px-Limerick-King-Johns-Castle-2012.JPG")!
    ]

    private let images: [UIImage] = (1...8).compactMap { UIImage(named: "demo\($0)") }

    private var allUsersIds: [Int] {
        return Array([users, [receiverId]].joined())
    }

    init(receiverId: Int, usersIds: [Int]) {
        self.users = usersIds
        self.receiverId = receiverId
    }

    func loadInitialMessages(completion: @escaping ([RawMessage]) -> Void) {
        restartMessageTimer()
        restartTypingTimer()
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            let messages = self.createBunchOfMessages(number: 50)
            if messages.count > 10 {
                self.lastReceivedUUID = messages[messages.count - 10].id
            }
            if messages.count > 3 {
                self.lastReadUUID = messages[messages.count - 3].id
            }
            DispatchQueue.main.async {
                completion(messages)
            }
        }
    }

    func loadPreviousMessages(completion: @escaping ([RawMessage]) -> Void) {
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            let messages = self.createBunchOfMessages(number: 50)

            DispatchQueue.main.async {
                completion(messages)
            }
        }
    }

    func stop() {
        messageTimer?.invalidate()
        messageTimer = nil
        typingTimer?.invalidate()
        typingTimer = nil
    }

    @objc
    private func handleTimer() {
        guard enableNewMessages else {
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
        guard enableTyping else {
            return
        }
        typingState = typingState == .idle ? TypingState.typing : .idle
        delegate?.typingStateChanged(to: typingState)
    }

    private func restartMessageTimer() {
        messageTimer?.invalidate()
        messageTimer = nil
        messageTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Int.random(in: 0...6)), target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
    }

    private func restartTypingTimer() {
        typingTimer?.invalidate()
        typingTimer = nil
        typingTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Int.random(in: 1...3)), target: self, selector: #selector(handleTypingTimer), userInfo: nil, repeats: true)
    }

    private func createRandomMessage(date: Date = Date()) -> RawMessage {
        let sender = allUsersIds[Int.random(in: 0..<allUsersIds.count)]
        lastMessageIndex += 1
        switch (Int.random(in: 0...8), enableRichContent) {
        case (6, true):
            return RawMessage(id: UUID(), date: date, data: .url(websiteUrls[Int.random(in: 0..<websiteUrls.count)]), userId: sender)
        case (5, true):
            return RawMessage(id: UUID(), date: date, data: .image(.imageURL(imageUrls[Int.random(in: 0..<imageUrls.count)])), userId: sender)
        case (7, true):
            return RawMessage(id: UUID(), date: date, data: .image(.image(images[Int.random(in: 0..<images.count)])), userId: sender)
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
