//
// ChatLayout
// ChatControllerDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

protocol ChatControllerDelegate: AnyObject {
    func update(with sections: [Section], requiresIsolatedProcess: Bool)
}
