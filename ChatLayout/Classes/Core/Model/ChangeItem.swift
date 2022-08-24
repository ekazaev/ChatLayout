//
// ChatLayout
// ChangeItem.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// Internal replacement for `UICollectionViewUpdateItem`.
enum ChangeItem: Equatable {

    /// Delete section at `sectionIndex`
    case sectionDelete(sectionIndex: Int)

    /// Delete item at `itemIndexPath`
    case itemDelete(itemIndexPath: IndexPath)

    /// Insert section at `sectionIndex`
    case sectionInsert(sectionIndex: Int)

    /// Insert item at `itemIndexPath`
    case itemInsert(itemIndexPath: IndexPath)

    /// Reload section at `sectionIndex`
    case sectionReload(sectionIndex: Int)

    /// Reload item at `itemIndexPath`
    case itemReload(itemIndexPath: IndexPath)

    /// Move section from `initialSectionIndex` to `finalSectionIndex`
    case sectionMove(initialSectionIndex: Int, finalSectionIndex: Int)

    /// Move item from `initialItemIndexPath` to `finalItemIndexPath`
    case itemMove(initialItemIndexPath: IndexPath, finalItemIndexPath: IndexPath)

    init?(with updateItem: UICollectionViewUpdateItem) {
        let updateAction = updateItem.updateAction
        let indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate
        let indexPathAfterUpdate = updateItem.indexPathAfterUpdate
        switch updateAction {
        case .none:
            return nil
        case .move:
            guard let indexPathBeforeUpdate = indexPathBeforeUpdate,
                  let indexPathAfterUpdate = indexPathAfterUpdate else {
                assertionFailure("`indexPathBeforeUpdate` and `indexPathAfterUpdate` cannot be `nil` for a `.move` update action.")
                return nil
            }
            if indexPathBeforeUpdate.item == NSNotFound, indexPathAfterUpdate.item == NSNotFound {
                self = .sectionMove(initialSectionIndex: indexPathBeforeUpdate.section, finalSectionIndex: indexPathAfterUpdate.section)
            } else {
                self = .itemMove(initialItemIndexPath: indexPathBeforeUpdate, finalItemIndexPath: indexPathAfterUpdate)
            }
        case .insert:
            guard let indexPath = indexPathAfterUpdate else {
                assertionFailure("`indexPathAfterUpdate` cannot be `nil` for an `.insert` update action.")
                return nil
            }
            if indexPath.item == NSNotFound {
                self = .sectionInsert(sectionIndex: indexPath.section)
            } else {
                self = .itemInsert(itemIndexPath: indexPath)
            }
        case .delete:
            guard let indexPath = indexPathBeforeUpdate else {
                assertionFailure("`indexPathBeforeUpdate` cannot be `nil` for a `.delete` update action.")
                return nil
            }
            if indexPath.item == NSNotFound {
                self = .sectionDelete(sectionIndex: indexPath.section)
            } else {
                self = .itemDelete(itemIndexPath: indexPath)
            }
        case .reload:
            guard let indexPath = indexPathAfterUpdate else {
                assertionFailure("`indexPathAfterUpdate` cannot be `nil` for a `.reload` update action.")
                return nil
            }

            if indexPath.item == NSNotFound {
                self = .sectionReload(sectionIndex: indexPath.section)
            } else {
                self = .itemReload(itemIndexPath: indexPath)
            }
        @unknown default:
            return nil
        }
    }

    private var rawValue: Int {
        switch self {
        case .sectionReload:
            return 0
        case .itemReload:
            return 1
        case .sectionDelete:
            return 2
        case .itemDelete:
            return 3
        case .sectionInsert:
            return 4
        case .itemInsert:
            return 5
        case .sectionMove:
            return 6
        case .itemMove:
            return 7
        }
    }

}

extension ChangeItem: Comparable {

    static func < (lhs: ChangeItem, rhs: ChangeItem) -> Bool {
        switch (lhs, rhs) {
        case let (.sectionDelete(sectionIndex: lIndex), .sectionDelete(sectionIndex: rIndex)):
            return lIndex < rIndex
        case let (.itemDelete(itemIndexPath: lIndexPath), .itemDelete(itemIndexPath: rIndexPath)):
            return lIndexPath < rIndexPath
        case let (.sectionInsert(sectionIndex: lIndex), .sectionInsert(sectionIndex: rIndex)):
            return lIndex < rIndex
        case let (.itemInsert(itemIndexPath: lIndexPath), .itemInsert(itemIndexPath: rIndexPath)):
            return lIndexPath < rIndexPath
        case let (.sectionReload(sectionIndex: lIndex), .sectionReload(sectionIndex: rIndex)):
            return lIndex < rIndex
        case let (.itemReload(itemIndexPath: lIndexPath), .itemReload(itemIndexPath: rIndexPath)):
            return lIndexPath < rIndexPath
        case let (.sectionMove(initialSectionIndex: lInitialSectionIndex, finalSectionIndex: lFinalSectionIndex),
                  .sectionMove(initialSectionIndex: rInitialSectionIndex, finalSectionIndex: rFinalSectionIndex)):
            if lInitialSectionIndex == rInitialSectionIndex {
                return lFinalSectionIndex < rFinalSectionIndex
            } else {
                return lInitialSectionIndex < rInitialSectionIndex
            }
        case let (.itemMove(initialItemIndexPath: lInitialIndexPath, finalItemIndexPath: lFinalIndexPath),
                  .itemMove(initialItemIndexPath: rInitialIndexPath, finalItemIndexPath: rFinalIndexPath)):
            if lInitialIndexPath == rInitialIndexPath {
                return lFinalIndexPath < rFinalIndexPath
            } else {
                return lInitialIndexPath < rInitialIndexPath
            }
        default:
            return lhs.rawValue < rhs.rawValue
        }
    }

}
