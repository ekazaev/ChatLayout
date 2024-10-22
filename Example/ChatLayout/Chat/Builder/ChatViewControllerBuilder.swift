//
// ChatLayout
// ChatViewControllerBuilder.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

struct ChatViewControllerBuilder {
    func build() -> NSUIViewController {
        let dataProvider = DefaultRandomDataProvider(receiverId: 0, usersIds: [1, 2, 3])
        let messageController = DefaultChatController(dataProvider: dataProvider, userId: 0)

        let editNotifier = EditNotifier()
        let swipeNotifier = SwipeNotifier()
        let dataSource = DefaultChatCollectionDataSource(editNotifier: editNotifier,
                                                         swipeNotifier: swipeNotifier,
                                                         reloadDelegate: messageController,
                                                         editingDelegate: messageController)

        dataProvider.delegate = messageController

        let messageViewController = ChatViewController(chatController: messageController, dataSource: dataSource, editNotifier: editNotifier, swipeNotifier: swipeNotifier)
        messageController.delegate = messageViewController

        return messageViewController
    }
}
