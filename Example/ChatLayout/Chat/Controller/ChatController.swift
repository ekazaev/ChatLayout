//
// ChatLayout
// ChatController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

@MainActor
protocol ChatController {
    var isAgentModeEnabled: Bool { get }

    var extendedLayoutMessageID: UUID? { get }

    func loadInitialMessages(completion: @escaping @MainActor @Sendable ([Section]) -> Void)

    func loadPreviousMessages(completion: @escaping @MainActor @Sendable ([Section]) -> Void)

    func sendMessage(_ data: Message.Data, completion: @escaping @MainActor @Sendable ([Section]) -> Void)

    func setAgentModeEnabled(_ isEnabled: Bool)

    func startAgentResponse()
}
