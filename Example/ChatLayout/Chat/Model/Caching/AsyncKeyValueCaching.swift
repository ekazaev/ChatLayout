//
// ChatLayout
// AsyncKeyValueCaching.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

public protocol AsyncKeyValueCaching: KeyValueCaching {
    func getEntity(for key: CachingKey, completion: @escaping @Sendable (Result<Entity, Error>) -> Void)
}

public extension AsyncKeyValueCaching {
    func getEntity(for key: CachingKey, completion: @escaping @Sendable (Result<Entity, Error>) -> Void) {
        Task.detached(priority: .utility) {
            do {
                try completion(.success(self.getEntity(for: key)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
