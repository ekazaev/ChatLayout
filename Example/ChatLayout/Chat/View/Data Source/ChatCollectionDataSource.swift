//
// ChatLayout
// ChatCollectionDataSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import ChatLayout
import Foundation
import UIKit

protocol ChatCollectionDataSource: UICollectionViewDataSource, ChatLayoutDelegate {

    var sections: [Section] { get set }

    func prepare(with collectionView: UICollectionView)

}
