//
// ChatLayout
// DateAccessoryController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

final class DateAccessoryController {
    private let date: Date

    let accessoryText: String

    init(date: Date) {
        self.date = date
        accessoryText = MessageDateFormatter.shared.string(from: date)
    }
}
