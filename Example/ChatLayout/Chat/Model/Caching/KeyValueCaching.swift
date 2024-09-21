//
// ChatLayout
// KeyValueCaching.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

public protocol KeyValueCaching {
    associatedtype CachingKey

    associatedtype Entity

    func isEntityCached(for key: CachingKey) -> Bool

    func getEntity(for key: CachingKey) throws -> Entity

    func store(entity: Entity, for key: CachingKey) throws
}
