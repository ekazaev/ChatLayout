//
// ChatLayout
// IterativeCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

public final class IterativeCache<FastCache: AsyncKeyValueCaching, SlowCache: AsyncKeyValueCaching>: AsyncKeyValueCaching where FastCache.CachingKey == SlowCache.CachingKey, FastCache.Entity == SlowCache.Entity {

    public let mainCache: FastCache

    public let backupCache: SlowCache

    public init(mainCache: FastCache, backupCache: SlowCache) {
        self.mainCache = mainCache
        self.backupCache = backupCache
    }

    public func isEntityCached(for key: FastCache.CachingKey) -> Bool {
        return mainCache.isEntityCached(for: key) || backupCache.isEntityCached(for: key)
    }

    public func getEntity(for key: FastCache.CachingKey) throws -> FastCache.Entity {
        if let image = try? mainCache.getEntity(for: key) {
            return image
        } else {
            return try backupCache.getEntity(for: key)
        }
    }

    public func getEntity(for key: FastCache.CachingKey, completion: @escaping (Result<FastCache.Entity, Error>) -> Void) {
        mainCache.getEntity(for: key, completion: { result in
            guard case .failure = result else {
                completion(result)
                return
            }

            self.backupCache.getEntity(for: key, completion: { result in
                switch result {
                case let .success(image):
                    completion(.success(image))
                    DispatchQueue.global(qos: .utility).async {
                        try? self.mainCache.store(entity: image, for: key)
                    }
                case let .failure(error):
                    completion(.failure(error))
                }
            })
        })
    }

    public func store(entity: FastCache.Entity, for key: FastCache.CachingKey) throws {
        try mainCache.store(entity: entity, for: key)
        try backupCache.store(entity: entity, for: key)
    }

}
