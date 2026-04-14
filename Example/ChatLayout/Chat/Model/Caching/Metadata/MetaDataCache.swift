//
// ChatLayout
// MetaDataCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import LinkPresentation
import UIKit

struct SendableLinkMetadata: @unchecked Sendable {
    let value: LPLinkMetadata

    init(_ value: LPLinkMetadata) {
        self.value = value
    }
}

final class MetaDataCache<Cache: AsyncKeyValueCaching>: AsyncKeyValueCaching, @unchecked Sendable where Cache.CachingKey == URL, Cache.Entity == Data {
    private let cache: Cache

    init(cache: Cache) {
        self.cache = cache
    }

    func isEntityCached(for url: URL) -> Bool {
        cache.isEntityCached(for: url)
    }

    func getEntity(for url: URL) throws -> SendableLinkMetadata {
        let data = try cache.getEntity(for: url)
        guard let entity = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data) else {
            throw CacheError.invalidData
        }
        return SendableLinkMetadata(entity)
    }

    func store(entity: SendableLinkMetadata, for key: URL) throws {
        let codedData = try NSKeyedArchiver.archivedData(withRootObject: entity.value, requiringSecureCoding: true)
        try cache.store(entity: codedData, for: key)
    }
}

extension URL: PersistentlyCacheable {
    var persistentIdentifier: String {
        guard let percentEncoding = absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            fatalError()
        }
        return percentEncoding
    }
}
