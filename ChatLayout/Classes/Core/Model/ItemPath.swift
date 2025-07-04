//
// ChatLayout
// ItemPath.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

/// Represents the location of an item in a section.
///
/// Initializing a `ItemPath` is measurably faster than initializing an `IndexPath`.
/// On an iPhone X, compiled with -Os optimizations, it's about 35x faster to initialize this struct
/// compared to an `IndexPath`.
struct ItemPath: Hashable, Sendable {
    let section: Int

    let item: Int

    var indexPath: IndexPath {
        IndexPath(item: item, section: section)
    }

    init(item: Int, section: Int) {
        self.section = section
        self.item = item
    }

    init(for indexPath: IndexPath) {
        section = indexPath.section
        item = indexPath.item
    }
}
