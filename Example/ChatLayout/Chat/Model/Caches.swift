//
// ChatLayout
// Caches.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

let loader = CachingImageLoader(cache: imageCache, loader: DefaultImageLoader())

@available(iOS 13, *)
var metadataCache = IterativeCache(mainCache: MetaDataCache(cache: MemoryDataCache<URL>()),
                                   backupCache: MetaDataCache(cache: PersistentDataCache<URL>(cacheFileExtension: "metadataCache")))

let imageCache = IterativeCache(mainCache: ImageForUrlCache(cache: MemoryDataCache<CacheableImageKey>()),
                                backupCache: ImageForUrlCache(cache: PersistentDataCache<CacheableImageKey>()))

//// Uncomment to reload dynamic content on every start.
// @available(iOS 13, *)
// var metadataCache = MetaDataCache(cache: MemoryDataCache<URL>())
//
// let imageCache = ImageForUrlCache(cache: MemoryDataCache<CacheableImageKey>())
