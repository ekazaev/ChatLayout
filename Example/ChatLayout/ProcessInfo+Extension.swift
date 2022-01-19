//
// ChatLayout
// ProcessInfo+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation

extension ProcessInfo {

    static var isRunningTests: Bool {
        return processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

}
