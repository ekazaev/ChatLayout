//
// ChatLayout
// MockUICollectionViewUpdateItem.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
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
        self._indexPathBeforeUpdate = indexPathBeforeUpdate
        self._indexPathAfterUpdate = indexPathAfterUpdate
        self._updateAction = action
        super.init()
    }

    override var indexPathBeforeUpdate: IndexPath? {
        return _indexPathBeforeUpdate
    }

    override var indexPathAfterUpdate: IndexPath? {
        return _indexPathAfterUpdate
    }

    override var updateAction: Action {
        return _updateAction
    }

}
