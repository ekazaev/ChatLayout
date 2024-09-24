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
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

protocol ChatCollectionDataSource: NSUICollectionViewDataSource, ChatLayoutDelegate {
    var sections: [Section] { get set }

    func prepare(with collectionView: NSUICollectionView)
}
