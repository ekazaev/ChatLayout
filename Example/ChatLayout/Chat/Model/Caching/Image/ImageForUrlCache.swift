//
// ChatLayout
// ImageForUrlCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public final class ImageForUrlCache<Cache: AsyncKeyValueCaching>: AsyncKeyValueCaching where Cache.CachingKey: Hashable, Cache.Entity == Data {
    private let cache: Cache

    public init(cache: Cache) {
        self.cache = cache
    }

    public func isEntityCached(for key: CachingKey) -> Bool {
        cache.isEntityCached(for: key)
    }

    public func getEntity(for key: CachingKey) throws -> NSUIImage {
        let data = try cache.getEntity(for: key)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        guard let image = NSUIImage(data: data) else {
            throw CacheError.invalidData
        }
        return image
        #endif

        #if canImport(UIKit)
        guard let image = NSUIImage(data: data, scale: 1) else {
            throw CacheError.invalidData
        }
        return image
        #endif
    }

    public func getEntity(for key: Cache.CachingKey, completion: @escaping (Result<NSUIImage, Error>) -> Void) {
        cache.getEntity(for: key, completion: { result in
            DispatchQueue.global(qos: .utility).async {
                switch result {
                case let .success(data):
                    guard let image = NSUIImage(data: data) else {
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

    public func store(entity: NSUIImage, for key: Cache.CachingKey) throws {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        guard let data = entity.tiffRepresentation else {
            return
        }
        #endif

        #if canImport(UIKit)
        guard let data = entity.jpegData(compressionQuality: 1.0) else {
            return
        }
        #endif
        try cache.store(entity: data, for: key)
    }
}
