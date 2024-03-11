//
// ChatLayout
// URLSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

struct URLSource: Hashable {
    let url: URL

    var isPresentLocally: Bool {
        if #available(iOS 13, *) {
            metadataCache.isEntityCached(for: url)
        } else {
            true
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(isPresentLocally)
    }
}
