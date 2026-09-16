//
// ChatLayout
// KeyValueCaching.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

let concurrentCachingQueue = DispatchQueue(
    label: "KeyValueCaching",
    qos: .userInteractive,
    attributes: .concurrent
)

public protocol KeyValueCaching: Sendable {
    associatedtype CachingKey: Hashable & Sendable

    associatedtype Entity: Sendable

    func isEntityCached(for key: CachingKey) -> Bool

    func getEntity(for key: CachingKey) throws -> Entity

    func store(entity: Entity, for key: CachingKey) throws
}
