//
// ChatLayout
// DifferenceKit+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2021.
// Distributed under the MIT license.
//

import DifferenceKit
import Foundation
import UIKit

extension UICollectionView {

    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        onInterruptedReload: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil,
        setData: ((C) -> Void)?
    ) {
        if case .none = window, let data = stagedChangeset.last?.data {
            setData?(data)
            if let onInterruptedReload = onInterruptedReload {
                onInterruptedReload()
            } else {
                reloadData()
            }
            completion?(false)
            return
        }

        func perfomUpdate(changeset: Changeset<C>, performCompletion: ((Bool) -> Void)?) {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData?(data)
                if let onInterruptedReload = onInterruptedReload {
                    onInterruptedReload()
                } else {
                    reloadData()
                }
                completion?(false)
                performCompletion?(false)
                return
            }

            performBatchUpdates({
                setData?(changeset.data)

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
            }, completion: { result in performCompletion?(result) })
        }

        func performInSeries(stagedChangeset: StagedChangeset<C>) {
            var stagedChangeset = stagedChangeset
            if !stagedChangeset.isEmpty, let item = stagedChangeset.first {
                stagedChangeset.removeFirst()
                perfomUpdate(changeset: item) { result in
                    guard result else { return }
                    performInSeries(stagedChangeset: stagedChangeset)
                }
                return
            }
            completion?(true)
        }

        func perfomInConcurrency() {
            let dispatchGroup: DispatchGroup? = completion != nil ? DispatchGroup() : nil
            dispatchGroup?.notify(queue: .main) {
                completion?(true)
            }
            for changeset in stagedChangeset {
                dispatchGroup?.enter()
                perfomUpdate(changeset: changeset) { result in dispatchGroup?.leave() }
            }
        }

        if #available(iOS 15, *) {
            performInSeries(stagedChangeset: stagedChangeset)
        } else {
            perfomInConcurrency()
        }
    }

}

extension StagedChangeset {

    // DifferenceKit splits different type of actions into the different change sets to avoid the limitations of UICollectionView
    // But it may lead to the situations that `UICollectionViewLayout` doesnt know what change will happen next within the single portion
    // of changes. As we know that at least insertions and deletions can be processed together, we fix that in the StagedChangeset we got from
    // DifferenceKit.
    func flattenIfPossible() -> StagedChangeset {
        if count == 2,
            self[0].sectionChangeCount == 0,
            self[1].sectionChangeCount == 0,
            self[0].elementDeleted.count == self[0].elementChangeCount,
            self[1].elementInserted.count == self[1].elementChangeCount {
            return StagedChangeset(arrayLiteral: Changeset(data: self[1].data, elementDeleted: self[0].elementDeleted, elementInserted: self[1].elementInserted))
        }
        return self
    }

    func mergeChangesIfPossible() -> StagedChangeset {
        if #available(iOS 15, *), var lastItem = self.last {
            var stagedChangeset = self
            let numberOfData = lastItem.data.count

            let sectionDeleted = stagedChangeset.flatMap({ $0.sectionDeleted })
            let sectionInserted = stagedChangeset.flatMap({ $0.sectionInserted })
            let sectionUpdated = stagedChangeset.flatMap({ $0.sectionUpdated })
            let sectionMoved = stagedChangeset.flatMap({ $0.sectionMoved })

            var elementDeleted = stagedChangeset.flatMap({ $0.elementDeleted })
            var elementInserted = stagedChangeset.flatMap({ $0.elementInserted })
            let elementUpdated = stagedChangeset.flatMap({ $0.elementUpdated })
            let elementMoved = stagedChangeset.flatMap({ $0.elementMoved })

            guard sectionDeleted.count == 0, sectionInserted.count == 0, sectionUpdated.count == 0, sectionMoved.count == 0,
                  !elementDeleted.map({ $0.element }).contains(where: { $0 >= numberOfData }),
                  !elementInserted.map({ $0.element }).contains(where: { $0 >= numberOfData }),
                  !elementUpdated.map({ $0.element }).contains(where: { $0 >= numberOfData }),
                  elementMoved.count == 0 else {
                // too complicated to merge
                return self
            }

            // Try to reduce actions: if an item needs to be updated there is no need to remove or insert that same item before.
            elementUpdated.map({ $0.element }).forEach { elementToUpdate in
                elementDeleted.removeAll(where: { $0.element == elementToUpdate })
                elementInserted.removeAll(where: { $0.element == elementToUpdate })
            }

            // merge all elements in one item
            lastItem.removeElements()
            lastItem.updateElements(deleted: elementDeleted, inserted: elementInserted, updated: elementUpdated)

            stagedChangeset.removeAll()
            stagedChangeset.append(lastItem)
            return stagedChangeset
        }

        return self
    }
}


private extension Changeset {
    mutating func removeElements() {
        self.elementDeleted.removeAll()
        self.elementInserted.removeAll()
        self.elementUpdated.removeAll()
        self.elementMoved.removeAll()
    }

    mutating func updateElements(deleted: [ElementPath], inserted: [ElementPath], updated: [ElementPath]) {
        self.elementDeleted.append(contentsOf: deleted)
        self.elementInserted.append(contentsOf: inserted)
        self.elementUpdated.append(contentsOf: updated)
    }
}
