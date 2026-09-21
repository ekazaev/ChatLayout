//
// ChatLayout
// IterativeCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

private let iterativeTargetQueue: DispatchQueue = .init(label: "IterativeCache", qos: .userInteractive, attributes: .concurrent)

public final class IterativeCache<FastCache: AsyncKeyValueCaching, SlowCache: AsyncKeyValueCaching>: AsyncKeyValueCaching, @unchecked Sendable
    where
    FastCache.CachingKey == SlowCache.CachingKey, FastCache.Entity == SlowCache.Entity {
    public typealias CachingKey = FastCache.CachingKey
    public typealias Entity = FastCache.Entity
    public let mainCache: FastCache

    public let backupCache: SlowCache

    private let queue: DispatchQueue

    public init(mainCache: FastCache, backupCache: SlowCache) {
        self.mainCache = mainCache
        self.backupCache = backupCache
        queue = DispatchQueue(
            label: "iterative-cache-\(CachingKey.self)-\(Entity.self)",
            qos: .userInteractive,
            attributes: .concurrent,
            target: iterativeTargetQueue
        )
    }

    public func isEntityCached(for key: FastCache.CachingKey) -> Bool {
        mainCache.isEntityCached(for: key) || backupCache.isEntityCached(for: key)
    }

    public func getEntity(for key: FastCache.CachingKey) throws -> FastCache.Entity {
        if let entity = try? queue.sync(execute: { try mainCache.getEntity(for: key) }) {
            return entity
        }
        let entity = try backupCache.getEntity(for: key)
        try? queue.sync(flags: .barrier) { try mainCache.store(entity: entity, for: key) }
        return entity
    }

    public func getEntity(
        for key: FastCache.CachingKey,
        completion: @escaping @Sendable (Result<FastCache.Entity, Error>) -> Void
    ) {
        mainCache.getEntity(for: key, completion: { result in
            guard case .failure = result else {
                completion(result)
                return
            }

            self.backupCache.getEntity(for: key, completion: { result in
                switch result {
                case let .success(image):
                    completion(.success(image))
                    self.queue.async(flags: .barrier) {
                        try? self.mainCache.store(entity: image, for: key)
                    }
                case let .failure(error):
                    completion(.failure(error))
                }
            })
        })
    }

    public func store(entity: FastCache.Entity, for key: FastCache.CachingKey) throws {
        try queue.sync(flags: .barrier) {
            try mainCache.store(entity: entity, for: key)
            try backupCache.store(entity: entity, for: key)
        }
    }
}
