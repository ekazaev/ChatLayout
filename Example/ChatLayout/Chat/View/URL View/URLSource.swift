//
// ChatLayout
// URLSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

struct URLSource: Hashable {
    let url: URL

    var isPresentLocally: Bool {
        metadataCache.isEntityCached(for: url)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(isPresentLocally)
    }
}
