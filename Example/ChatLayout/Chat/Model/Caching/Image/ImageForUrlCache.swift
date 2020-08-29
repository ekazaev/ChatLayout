//
// ChatLayout
// ImageForUrlCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

public final class ImageForUrlCache<Cache: AsyncKeyValueCaching>: AsyncKeyValueCaching where Cache.CachingKey: Hashable, Cache.Entity == Data {

    private let cache: Cache

    public init(cache: Cache) {
        self.cache = cache
    }

    public func isEntityCached(for key: CachingKey) -> Bool {
        return cache.isEntityCached(for: key)
    }

    public func getEntity(for key: CachingKey) throws -> UIImage {
        let data = try cache.getEntity(for: key)
        guard let image = UIImage(data: data, scale: 1) else {
            throw CacheError.invalidData
        }
        return image
    }

    public func getEntity(for key: Cache.CachingKey, completion: @escaping (Result<UIImage, Error>) -> Void) {
        cache.getEntity(for: key, completion: { result in
            DispatchQueue.global(qos: .utility).async {
                switch result {
                case let .success(data):
                    guard let image = UIImage(data: data) else {
                        DispatchQueue.main.async {
                            completion(.failure(CacheError.invalidData))
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                case let .failure(error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
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
