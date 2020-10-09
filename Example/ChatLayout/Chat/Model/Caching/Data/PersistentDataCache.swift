//
// ChatLayout
// PersistentDataCache.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

private let expirationFileAttribute = "saks.persistent-auto-purging-cache.expiration"

class PersistentDataCache<CachingKey: PersistentlyCacheable>: AsyncKeyValueCaching {

    private let fileManager = FileManager()

    private let persistencePath: String

    private let queue = DispatchQueue.global()

    private let defaultTimeToLive: TimeInterval

    private let cacheFileExtension: String

    init(defaultTimeToLive: TimeInterval = 7 * 24 * 3600,
         persistencePath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!,
         cacheFileExtension: String = String(describing: CachingKey.self)) {
        self.persistencePath = persistencePath
        self.defaultTimeToLive = defaultTimeToLive
        self.cacheFileExtension = cacheFileExtension.addingPercentEncoding(withAllowedCharacters: .letters)!

        var isDir: ObjCBool = false
        precondition(fileManager.fileExists(atPath: persistencePath, isDirectory: &isDir) && isDir.boolValue, "The persistence path should exist, and it should be a directory")
        cleanup()
    }

    func isEntityCached(for key: CachingKey) -> Bool {
        let path = getPath(for: key.persistentIdentifier)
        return fileManager.fileExists(atPath: path)
    }

    func getEntity(for key: CachingKey) throws -> Data {
        let path = getPath(for: key.persistentIdentifier)
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return data
        } catch {
            try fileManager.removeItem(atPath: path)
            throw CacheError.invalidData
        }
    }

    func getEntity(for key: CachingKey, completion: @escaping (Result<Data, Error>) -> Void) {
        queue.async {
            do {
                let data = try self.getEntity(for: key)
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(CacheError.invalidData))
                }
            }
        }
    }

    func store(entity: Data, for key: CachingKey) {
        queue.async {
            let path = self.getPath(for: key.persistentIdentifier)

            defer {
                if self.fileManager.fileExists(atPath: path) {
                    var expiration = Date().addingTimeInterval(self.defaultTimeToLive).timeIntervalSince1970

                    setxattr(path, expirationFileAttribute, &expiration, MemoryLayout<TimeInterval>.size, 0, 0)
                }
            }

            guard !self.fileManager.fileExists(atPath: path) else {
                return
            }

            try? entity.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
    }

    private func cleanup() {
        queue.sync {
            let files = self.cachedFileNames()

            for fileName in files {
                let identifier = identifierFromFileName(fileName)
                guard let life = remainingLife(for: identifier),
                    life <= 0 else {
                    continue
                }

                try? self.fileManager.removeItem(atPath: self.getPath(for: identifier))
            }
        }
    }

    private func getPath(for fileName: String) -> String {
        return (persistencePath as NSString).appendingPathComponent("\(fileName).\(cacheFileExtension)")
    }

    private func identifierFromFileName(_ fileName: String) -> String {
        return fileName.replacingOccurrences(of: ".\(cacheFileExtension)", with: "")
    }

    private func remainingLife(for fileName: String) -> TimeInterval? {
        let path = getPath(for: fileName)
        guard fileManager.fileExists(atPath: path) else {
            return nil
        }

        var expiration: TimeInterval = 0
        getxattr(path, expirationFileAttribute, &expiration, MemoryLayout<TimeInterval>.size, 0, 0)

        return expiration - NSDate().timeIntervalSince1970
    }

    private func cachedFileNames() -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(atPath: persistencePath).filter({ $0.hasSuffix(".\(cacheFileExtension)") }) else {
            return []
        }

        return files
    }

}
