//
// ChatLayout
// MemoryDataCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

public final class MemoryDataCache<CachingKey: Hashable>: AsyncKeyValueCaching {

    private final class WrappedKey: NSObject {

        let key: CachingKey

        init(_ key: CachingKey) {
            self.key = key
        }

        override var hash: Int {
            return key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }

    }

    private final class Entry {

        let data: Data

        init(_ data: Data) {
            self.data = data
        }

    }

    private let cache = NSCache<WrappedKey, Entry>()

    private let lock = NSLock()

    public init() {
        cache.countLimit = Int.max
    }

    public func isEntityCached(for key: CachingKey) -> Bool {
        return cache.object(forKey: WrappedKey(key)) != nil
    }

    public func getEntity(for key: CachingKey) throws -> Data {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let entry = cache.object(forKey: WrappedKey(key)) else {
            throw CacheError.notFound
        }

        return entry.data
    }

    public func getEntity(for key: CachingKey, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let data = try? getEntity(for: key) else {
            completion(.failure(CacheError.notFound))
            return
        }

        completion(.success(data))
    }

    public func store(entity: Data, for key: CachingKey) {
        cache.setObject(Entry(entity), forKey: WrappedKey(key), cost: Int(Date().timeIntervalSince1970))
    }

}
