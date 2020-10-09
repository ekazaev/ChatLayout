//
// ChatLayout
// CachingImageLoader.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
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

    public func loadImage(from url: URL,
                          completion: @escaping (Result<UIImage, Error>) -> Void) {
        let imageKey = CacheableImageKey(url: url)
        cache.getEntity(for: imageKey, completion: { result in
            guard case .failure = result else {
                completion(result)
                return
            }
            self.loader.loadImage(from: url, completion: { result in
                switch result {
                case let .success(image):
                    try? self.cache.store(entity: image, for: imageKey)
                    completion(.success(image))
                case .failure:
                    completion(result)
                }
            })
        })
    }

}
