//
// ChatLayout
// DifferenceKit+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import DifferenceKit
import Foundation
import UIKit

public extension UICollectionView {

    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        onInterruptedReload: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil,
        setData: (C) -> Void
    ) {
        if case .none = window, let data = stagedChangeset.last?.data {
            setData(data)
            if let onInterruptedReload = onInterruptedReload {
                onInterruptedReload()
            } else {
                reloadData()
            }
            completion?(false)
            return
        }

        let dispatchGroup: DispatchGroup? = completion != nil
            ? DispatchGroup()
            : nil
        let completionHandler: ((Bool) -> Void)? = completion != nil
            ? { _ in
                dispatchGroup!.leave()
            }
            : nil

        for changeset in stagedChangeset {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData(data)
                if let onInterruptedReload = onInterruptedReload {
                    onInterruptedReload()
                } else {
                    reloadData()
                }
                completion?(false)
                return
            }

            performBatchUpdates({
                setData(changeset.data)
                dispatchGroup?.enter()

                if !changeset.sectionDeleted.isEmpty {
                    deleteSections(IndexSet(changeset.sectionDeleted))
                }

                if !changeset.sectionInserted.isEmpty {
                    insertSections(IndexSet(changeset.sectionInserted))
                }

                if !changeset.sectionUpdated.isEmpty {
                    reloadSections(IndexSet(changeset.sectionUpdated))
                }

                for (source, target) in changeset.sectionMoved {
                    moveSection(source, toSection: target)
                }

                if !changeset.elementDeleted.isEmpty {
                    deleteItems(at: changeset.elementDeleted.map {
                        IndexPath(item: $0.element, section: $0.section)
                    })
                }

                if !changeset.elementInserted.isEmpty {
                    insertItems(at: changeset.elementInserted.map {
                        IndexPath(item: $0.element, section: $0.section)
                    })
                }

                if !changeset.elementUpdated.isEmpty {
                    reloadItems(at: changeset.elementUpdated.map {
                        IndexPath(item: $0.element, section: $0.section)
                    })
                }

                for (source, target) in changeset.elementMoved {
                    moveItem(at: IndexPath(item: source.element, section: source.section), to: IndexPath(item: target.element, section: target.section))
                }
            }, completion: completionHandler)
        }
        dispatchGroup?.notify(queue: .main) {
            completion!(true)
        }
    }

}
