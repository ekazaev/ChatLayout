//
// ChatLayout
// ChatCollectionDataSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
import UIKit
import RecyclerView

protocol ChatCollectionDataSource: UICollectionViewDataSource, ChatLayoutDelegate, RecyclerViewDataSource<Cell.Identifier, VoidPayload>, SimpleLayoutEngineDelegate {

    var sections: [Section] { get set }

    func prepare(with collectionView: UICollectionView)
}
