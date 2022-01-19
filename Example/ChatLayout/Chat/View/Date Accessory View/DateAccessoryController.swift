//
// ChatLayout
// DateAccessoryController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation

final class DateAccessoryController {

    private let date: Date

    let accessoryText: String

    init(date: Date) {
        self.date = date
        self.accessoryText = MessageDateFormatter.shared.string(from: date)
    }

}
