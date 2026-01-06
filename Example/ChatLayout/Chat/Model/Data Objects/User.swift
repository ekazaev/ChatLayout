//
// ChatLayout
// User.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import DifferenceKit
import Foundation
import UIKit

struct User: Hashable {
    var id: Int

    var name: String {
        switch id {
        case 0:
            "Chat Layout"
        case 1:
            "Eugene Kazaev"
        case 2:
            "Cathal Murphy"
        case 3:
            "Aliaksandra Mikhailouskaya"
        default:
            fatalError()
        }
    }
}

extension User: Differentiable {}
