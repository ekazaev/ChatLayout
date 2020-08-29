//
// ChatLayout
// User.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import DifferenceKit
import Foundation
import UIKit

struct User: Hashable {

    var id: Int

    var name: String {
        switch id {
        case 0:
            return "Chat Layout"
        case 1:
            return "Eugene Kazaev"
        case 2:
            return "Cathal Murphy"
        case 3:
            return "Aliaksandra Mikhailouskaya"
        default:
            fatalError()
        }
    }

}

extension User: Differentiable {}
