//
// ChatLayout
// IndexPath+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

extension IndexPath {
    var itemPath: ItemPath {
        ItemPath(for: self)
    }
}
