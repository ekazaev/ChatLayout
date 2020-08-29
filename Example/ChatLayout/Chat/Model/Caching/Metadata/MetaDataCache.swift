//
// ChatLayout
// MetaDataCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import LinkPresentation
import UIKit

@available(iOS 13, *)
final class MetaDataCache<Cache: AsyncKeyValueCaching>: AsyncKeyValueCaching where Cache.CachingKey == URL, Cache.Entity == Data {

    private var cache: Cache

    init(cache: Cache) {
        self.cache = cache
    }

    func isEntityCached(for url: URL) -> Bool {
        return cache.isEntityCached(for: url)
    }

    func getEntity(for url: URL) throws -> LPLinkMetadata {
        let data = try cache.getEntity(for: url)
        let entity = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! LPLinkMetadata
        return entity
    }

    func getEntity(for key: URL, completion: @escaping (Result<LPLinkMetadata, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let entity = try self.getEntity(for: key)
                DispatchQueue.main.async {
                    completion(.success(entity))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func store(entity: LPLinkMetadata, for key: URL) throws {
        let codedData = try! NSKeyedArchiver.archivedData(withRootObject: entity, requiringSecureCoding: true)
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
