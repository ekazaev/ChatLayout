//
// ChatLayout
// CacheError.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

public enum CacheError: Error {
    case notFound

    case invalidData

    case custom(Error)
}
