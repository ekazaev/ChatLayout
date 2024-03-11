//
// ChatLayout
// ProcessInfo+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

extension ProcessInfo {
    static var isRunningTests: Bool {
        processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
