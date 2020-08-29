//
// ChatLayout
// URLSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

struct URLSource: Hashable {

    let url: URL

    var isPresentLocally: Bool {
        if #available(iOS 13, *) {
            return metadataCache.isEntityCached(for: url)
        } else {
            return true
        }

    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(isPresentLocally)
    }

}
