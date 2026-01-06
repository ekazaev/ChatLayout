//
// ChatLayout
// RawMessage.swift
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

struct RawMessage: Hashable {
    enum Data: Hashable {
        case text(String)

        case url(URL)

        case image(ImageMessageSource)
    }

    var id: UUID

    var date: Date

    var data: Data

    var userId: Int

    var status: MessageStatus = .sent
}
