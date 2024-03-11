//
// ChatLayout
// MockUICollectionViewUpdateItem.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

@testable import ChatLayout
import Foundation
import UIKit

class MockUICollectionViewUpdateItem: UICollectionViewUpdateItem {
    // swiftlint:disable identifier_name
    var _indexPathBeforeUpdate: IndexPath?
    var _indexPathAfterUpdate: IndexPath?
    var _updateAction: Action
    // swiftlint:enable identifier_name

    init(indexPathBeforeUpdate: IndexPath?, indexPathAfterUpdate: IndexPath?, action: Action) {
        _indexPathBeforeUpdate = indexPathBeforeUpdate
        _indexPathAfterUpdate = indexPathAfterUpdate
        _updateAction = action
        super.init()
    }

    override var indexPathBeforeUpdate: IndexPath? {
        _indexPathBeforeUpdate
    }

    override var indexPathAfterUpdate: IndexPath? {
        _indexPathAfterUpdate
    }

    override var updateAction: Action {
        _updateAction
    }
}
