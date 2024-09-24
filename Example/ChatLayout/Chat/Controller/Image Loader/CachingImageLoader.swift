//
// ChatLayout
// CachingImageLoader.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
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

public struct CachingImageLoader<C: AsyncKeyValueCaching>: ImageLoader where C.CachingKey == CacheableImageKey, C.Entity == NSUIImage {
    private let cache: C

    private let loader: ImageLoader

    public init(cache: C, loader: ImageLoader) {
        self.cache = cache
        self.loader = loader
    }

    public func loadImage(from url: URL,
                          completion: @escaping (Result<NSUIImage, Error>) -> Void) {
        let imageKey = CacheableImageKey(url: url)
        cache.getEntity(for: imageKey, completion: { result in
            guard case .failure = result else {
                completion(result)
                return
            }
            loader.loadImage(from: url, completion: { result in
                switch result {
                case let .success(image):
                    try? cache.store(entity: image, for: imageKey)
                    completion(.success(image))
                case .failure:
                    completion(result)
                }
            })
        })
    }
}
