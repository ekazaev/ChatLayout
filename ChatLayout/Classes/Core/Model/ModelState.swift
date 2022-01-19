//
// ChatLayout
// ModelState.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation

enum ModelState: Hashable, CaseIterable {

    case beforeUpdate

    case afterUpdate

    func hash(into hasher: inout Hasher) {
        switch self {
        case .afterUpdate:
            hasher.combine(1)
        case .beforeUpdate:
            hasher.combine(0)
        }
    }

}
