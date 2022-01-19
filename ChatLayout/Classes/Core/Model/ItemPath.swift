//
// ChatLayout
// ItemPath.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation

/// Represents the location of an item in a section.
///
/// Initializing a `ItemPath` is measurably faster than initializing an `IndexPath`.
/// On an iPhone X, compiled with -Os optimizations, it's about 35x faster to initialize this struct
/// compared to an `IndexPath`.
struct ItemPath: Hashable {

    let section: Int

    let item: Int

    var indexPath: IndexPath {
        return IndexPath(item: item, section: section)
    }

    init(item: Int, section: Int) {
        self.section = section
        self.item = item
    }

    init(for indexPath: IndexPath) {
        self.section = indexPath.section
        self.item = indexPath.item
    }

}
