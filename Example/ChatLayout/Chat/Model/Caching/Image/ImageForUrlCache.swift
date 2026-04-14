//
// ChatLayout
// ImageForUrlCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

public final class ImageForUrlCache<Cache: AsyncKeyValueCaching>: AsyncKeyValueCaching, @unchecked Sendable where Cache.CachingKey: Hashable, Cache.Entity == Data {
    private let cache: Cache

    public init(cache: Cache) {
        self.cache = cache
    }

    public func isEntityCached(for key: CachingKey) -> Bool {
        cache.isEntityCached(for: key)
    }

    public func getEntity(for key: CachingKey) throws -> UIImage {
        let data = try cache.getEntity(for: key)
        guard let image = UIImage(data: data, scale: 1) else {
            throw CacheError.invalidData
        }
        return image
    }

    public func getEntity(
        for key: Cache.CachingKey,
        completion: @escaping @Sendable (Result<UIImage, Error>) -> Void
    ) {
        cache.getEntity(for: key, completion: { result in
            switch result {
            case let .success(data):
                Task.detached(priority: .utility) {
                    guard let image = UIImage(data: data) else {
                        await MainActor.run {
                            completion(.failure(CacheError.invalidData))
                        }
                        return
                    }
                    await MainActor.run {
                        completion(.success(image))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }

    public func store(entity: UIImage, for key: Cache.CachingKey) throws {
        guard let data = entity.jpegData(compressionQuality: 1.0) else {
            return
        }
        try cache.store(entity: data, for: key)
    }
}
