//
// ChatLayout
// ChatViewControllerBuilder.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct ChatViewControllerBuilder {

    func build() -> UIViewController {
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
