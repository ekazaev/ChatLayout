//
// ChatLayout
// Caches.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

let loader: CachingImageLoader = .init(cache: imageCache, loader: DefaultImageLoader())

let metadataCache: IterativeCache = .init(
    mainCache: MetaDataCache(cache: MemoryDataCache<URL>()),
    backupCache: MetaDataCache(cache: PersistentDataCache<URL>(cacheFileExtension: "metadataCache"))
)

let imageCache: IterativeCache = .init(
    mainCache: ImageForURLCache(cache: MemoryDataCache<CacheableImageKey>()),
    backupCache: ImageForURLCache(cache: PersistentDataCache<CacheableImageKey>())
)

// Uncomment to reload dynamic content on every start.
// let metadataCache = MetaDataCache(cache: MemoryDataCache<URL>())
//
// let imageCache = ImageForURLCache(cache: MemoryDataCache<CacheableImageKey>())
