//
// ChatLayout
// ChangeItem.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// Internal replacement for `UICollectionViewUpdateItem`.
enum ChangeItem: Equatable, Sendable {
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

    /// Reconfigure item at `itemIndexPath`
    case itemReconfigure(itemIndexPath: IndexPath)

    /// Move section from `initialSectionIndex` to `finalSectionIndex`
    case sectionMove(initialSectionIndex: Int, finalSectionIndex: Int)

    /// Move item from `initialItemIndexPath` to `finalItemIndexPath`
    case itemMove(initialItemIndexPath: IndexPath, finalItemIndexPath: IndexPath)

    @MainActor
    init?(with updateItem: UICollectionViewUpdateItem) {
        let updateAction = updateItem.updateAction
        let indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate
        let indexPathAfterUpdate = updateItem.indexPathAfterUpdate
        switch updateAction {
        case .none:
            return nil
        case .move:
            guard let indexPathBeforeUpdate,
                  let indexPathAfterUpdate else {
                assertionFailure("`indexPathBeforeUpdate` and `indexPathAfterUpdate` cannot be `nil` for a `.move` update action.")
                return nil
            }
            if indexPathBeforeUpdate.item == NSNotFound, indexPathAfterUpdate.item == NSNotFound {
                self = .sectionMove(
                    initialSectionIndex: indexPathBeforeUpdate.section,
                    finalSectionIndex: indexPathAfterUpdate.section
                )
            } else {
                self = .itemMove(
                    initialItemIndexPath: indexPathBeforeUpdate,
                    finalItemIndexPath: indexPathAfterUpdate
                )
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
            guard let indexPath = indexPathBeforeUpdate else {
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
}
