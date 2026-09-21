//
// ChatLayout
// ModelIdentifier.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

@MainActor
enum ModelIdentifierGenerator {
    private static var nextIdentifier: UInt64 = 0

    static func make() -> UInt64 {
        defer { nextIdentifier &+= 1 }
        return nextIdentifier
    }
}
