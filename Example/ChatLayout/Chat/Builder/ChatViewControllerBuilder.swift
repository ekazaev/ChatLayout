//
// ChatLayout
// ChatViewControllerBuilder.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct ChatViewControllerBuilder {

    func build() -> UIViewController {
        let dataProvider = DefaultRandomDataProvider(receiverId: 0, usersIds: [])
        let messageController = DefaultChatController(dataProvider: dataProvider, userId: 0)

        let editNotifier = EditNotifier()
        let dataSource: ChatCollectionDataSource
        if #available(iOS 13.0, *) {
            dataSource = DiffableChatCollectionDataSource(editNotifier: editNotifier,
                reloadDelegate: messageController,
                editingDelegate: messageController)
        } else {
            dataSource = DefaultChatCollectionDataSource(editNotifier: editNotifier,
                reloadDelegate: messageController,
                editingDelegate: messageController)
        }

        dataProvider.delegate = messageController

        let messageViewController = ChatViewController(chatController: messageController, dataSource: dataSource, editNotifier: editNotifier)
        messageController.delegate = messageViewController

        return messageViewController
    }

}
