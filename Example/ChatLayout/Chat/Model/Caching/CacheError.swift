//
// ChatLayout
// CacheError.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

public enum CacheError: Error {

    case notFound

    case invalidData

    case custom(Error)

}
