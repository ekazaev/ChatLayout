//
// ChatLayout
// ChatController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

protocol ChatController {

    func loadInitialMessages(completion: @escaping ([Section]) -> Void)

    func loadPreviousMessages(completion: @escaping ([Section]) -> Void)

    func sendMessage(_ data: Message.Data, completion: @escaping ([Section]) -> Void)

}
