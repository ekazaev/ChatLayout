//
// ChatLayout
// Caches.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation

let loader = CachingImageLoader(cache: imageCache, loader: DefaultImageLoader())

@available(iOS 13, *)
var metadataCache = IterativeCache(mainCache: MetaDataCache(cache: MemoryDataCache<URL>()),
                                   backupCache: MetaDataCache(cache: PersistentDataCache<URL>(cacheFileExtension: "metadataCache")))

let imageCache = IterativeCache(mainCache: ImageForUrlCache(cache: MemoryDataCache<CacheableImageKey>()),
                                backupCache: ImageForUrlCache(cache: PersistentDataCache<CacheableImageKey>()))

// Uncomment to reload dynamic content on every start.
// @available(iOS 13, *)
// var metadataCache = MetaDataCache(cache: MemoryDataCache<URL>())
//
// let imageCache = ImageForUrlCache(cache: MemoryDataCache<CacheableImageKey>())
