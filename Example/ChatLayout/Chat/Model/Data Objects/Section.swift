//
// ChatLayout
// Section.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

struct Section: Hashable {
    var id: Int

    var title: String

    var cells: [Cell]
}
