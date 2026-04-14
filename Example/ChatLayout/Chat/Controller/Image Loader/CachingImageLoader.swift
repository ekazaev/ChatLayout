//
// ChatLayout
// CachingImageLoader.swift
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

public struct CachingImageLoader<C: AsyncKeyValueCaching>: ImageLoader where C.CachingKey == CacheableImageKey, C.Entity == UIImage {
    private let cache: C

    private let loader: ImageLoader

    public init(cache: C, loader: ImageLoader) {
        self.cache = cache
        self.loader = loader
    }

    public func loadImage(from url: URL) async throws -> UIImage {
        let imageKey = CacheableImageKey(url: url)
        if let image = try? cache.getEntity(for: imageKey) {
            return image
        }

        let image = try await loader.loadImage(from: url)
        try? cache.store(entity: image, for: imageKey)
        return image
    }
}
