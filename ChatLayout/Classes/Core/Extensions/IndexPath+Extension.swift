//
// ChatLayout
// IndexPath+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation

extension IndexPath {

    var itemPath: ItemPath {
        return ItemPath(for: self)
    }

}
