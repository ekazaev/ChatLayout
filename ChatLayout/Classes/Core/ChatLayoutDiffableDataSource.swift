//
// ChatLayout
// ChatLayoutDiffableDataSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import UIKit

/// A diffable data source created specifically to coordinate `UICollectionView.reconfigureItems(at:)` with
/// `CollectionViewChatLayout.reconfigureItems(at:)`.
///
/// Apple's `UICollectionViewDiffableDataSource` forwards snapshot application to private `__UIDiffableDataSource` and
/// `_UIDiffableDataSourceViewUpdater` objects. Those objects use the private `_performDiffableUpdate(_:)` transaction and
/// an internal `commitAlongsideHandler` to replace identifier state while UIKit applies the view updates.
///
/// `ChatLayoutDiffableDataSource` cannot use those private hooks, so `commitAlongsideUpdates` exposes the equivalent
/// synchronization point within its public `performBatchUpdates` transaction. Clients must update any application-owned
/// models read by the cell provider and layout delegate in that closure so they remain consistent with the new snapshot.
@MainActor
open class ChatLayoutDiffableDataSource<SectionID: Hashable & Sendable, ItemID: Hashable & Sendable>: NSObject, UICollectionViewDataSource {
    private struct ItemLocation {
        let sectionID: SectionID
        let indexPath: IndexPath
    }

    private struct State: @unchecked Sendable {
        let snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>
        let itemLocations: [ItemID: ItemLocation]

        init(snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>) {
            self.snapshot = snapshot
            var itemLocations: [ItemID: ItemLocation] = [:]
            for (sectionIndex, sectionID) in snapshot.sectionIdentifiers.enumerated() {
                for (itemIndex, itemID) in snapshot.itemIdentifiers(inSection: sectionID).enumerated() {
                    itemLocations[itemID] = ItemLocation(
                        sectionID: sectionID,
                        indexPath: IndexPath(item: itemIndex, section: sectionIndex)
                    )
                }
            }
            self.itemLocations = itemLocations
        }
    }

    private struct ItemMove {
        let sourceIndexPath: IndexPath
        let destinationIndexPath: IndexPath
    }

    private struct SectionMove {
        let sourceIndex: Int
        let destinationIndex: Int
    }

    private struct SectionUpdates {
        let insertedIndexes: [Int]
        let deletedIndexes: [Int]
        let moves: [SectionMove]
        let insertedIDs: Set<SectionID>
        let deletedIDs: Set<SectionID>
    }

    private struct UpdatePlan {
        let insertedSections: [Int]
        let deletedSections: [Int]
        let movedSections: [SectionMove]
        let insertedItems: [IndexPath]
        let deletedItems: [IndexPath]
        let movedItems: [ItemMove]
        let reloadIndexPaths: [IndexPath]
        let reconfiguredIndexPaths: [IndexPath]
        let reconfiguringIndexPathsToIDs: [IndexPath: ItemID]
        let requiresReloadData: Bool

        var isEmpty: Bool {
            insertedSections.isEmpty &&
                deletedSections.isEmpty &&
                movedSections.isEmpty &&
                insertedItems.isEmpty &&
                deletedItems.isEmpty &&
                movedItems.isEmpty &&
                reloadIndexPaths.isEmpty &&
                reconfiguredIndexPaths.isEmpty
        }
    }

    /// The snapshot currently represented by the collection view, or `nil` before the first snapshot is applied.
    open var snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>? {
        state?.snapshot
    }

    private let collectionView: UICollectionView
    private let cellProvider: (UICollectionView, IndexPath, ItemID) -> UICollectionViewCell?
    private let onCellReconfiguration: ((UICollectionViewCell) -> Void)?

    private var reconfiguringIndexPathsToIDs: [IndexPath: ItemID]?
    private var state: State?

    /// Constructor.
    /// - Parameters:
    ///   - collectionView: The collection view managed by the data source.
    ///   - onCellReconfiguration: An optional closure called after `cellProvider` returns a cell for a reconfigured item.
    ///     The closure runs within the collection view's batch-update transaction and, when differences are animated,
    ///     within that update animation. Use it to perform additional actions alongside the update or to animate changes
    ///     within the cell itself.
    ///   - cellProvider: A closure that creates and configures a cell for an item identifier.
    public init(
        collectionView: UICollectionView,
        onCellReconfiguration: ((UICollectionViewCell) -> Void)? = nil,
        cellProvider: @escaping (UICollectionView, IndexPath, ItemID) -> UICollectionViewCell?
    ) {
        self.collectionView = collectionView
        self.onCellReconfiguration = onCellReconfiguration
        self.cellProvider = cellProvider
        super.init()
        collectionView.dataSource = self
    }

    /// Replaces the current snapshot and reloads the collection view.
    /// - Parameters:
    ///   - snapshot: The snapshot that replaces the current state.
    ///   - commitAlongsideUpdates: A closure that commits application-owned models before the collection view reloads its data.
    ///   - completion: An optional closure called after the new snapshot is applied.
    open func applySnapshotUsingReloadData(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
        commitAlongsideUpdates: () -> Void,
        completion: (() -> Void)? = nil
    ) {
        applySnapshotUsingReloadData(State(snapshot: snapshot), commitAlongsideUpdates: commitAlongsideUpdates)
        completion?()
    }

    /// Replaces the current snapshot, reloads the collection view, and returns after the new snapshot is applied.
    /// - Parameters:
    ///   - snapshot: The snapshot that replaces the current state.
    ///   - commitAlongsideUpdates: A closure that commits application-owned models before the collection view reloads its data.
    open func applySnapshotUsingReloadData(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
        commitAlongsideUpdates: () -> Void
    ) async {
        await withCheckedContinuation { continuation in
            applySnapshotUsingReloadData(snapshot, commitAlongsideUpdates: commitAlongsideUpdates) {
                continuation.resume()
            }
        }
    }

    /// Applies a snapshot while committing application-owned models alongside the collection-view update.
    /// - Parameters:
    ///   - snapshot: The snapshot that replaces the current state.
    ///   - animatingDifferences: A Boolean value that determines whether changes are animated.
    ///   - commitAlongsideUpdates: A closure that commits application-owned models within the collection-view update transaction.
    ///   - completion: An optional closure called after the collection view finishes applying the update.
    open func apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
        animatingDifferences: Bool,
        commitAlongsideUpdates: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        guard let state,
              collectionView.window != nil else {
            applySnapshotUsingReloadData(snapshot, commitAlongsideUpdates: commitAlongsideUpdates)
            completion?()
            return
        }

        let newState = State(snapshot: snapshot)
        let updatePlan = Self.makeUpdatePlan(from: state, to: newState)

        guard !updatePlan.requiresReloadData else {
            applySnapshotUsingReloadData(newState, commitAlongsideUpdates: commitAlongsideUpdates)
            completion?()
            return
        }

        guard !updatePlan.isEmpty else {
            self.state = newState
            commitAlongsideUpdates()
            completion?()
            return
        }

        let updates = {
            self.collectionView.performBatchUpdates({
                self.state = newState
                commitAlongsideUpdates()

                // Reconfiguration is addressed using pre-update index paths, but `state` already contains the new
                // snapshot. Looking up an old index path in that snapshot could resolve a different item after other
                // changes shifted it. Keep the old index-path-to-identifier mapping while UIKit requests the cells so
                // the provider receives the intended identifier without splitting the batch update.
                self.reconfiguringIndexPathsToIDs = updatePlan.reconfiguringIndexPathsToIDs
                self.collectionView.reconfigureItems(at: updatePlan.reconfiguredIndexPaths)
                (self.collectionView.collectionViewLayout as? CollectionViewChatLayout)?.reconfigureItems(at: updatePlan.reconfiguredIndexPaths)
                self.reconfiguringIndexPathsToIDs = nil

                self.collectionView.reloadItems(at: updatePlan.reloadIndexPaths)
                self.collectionView.deleteSections(IndexSet(updatePlan.deletedSections))
                self.collectionView.insertSections(IndexSet(updatePlan.insertedSections))
                updatePlan.movedSections.forEach {
                    self.collectionView.moveSection($0.sourceIndex, toSection: $0.destinationIndex)
                }
                self.collectionView.deleteItems(at: updatePlan.deletedItems)
                updatePlan.movedItems.forEach {
                    self.collectionView.moveItem(at: $0.sourceIndexPath, to: $0.destinationIndexPath)
                }
                self.collectionView.insertItems(at: updatePlan.insertedItems)
            }, completion: { _ in
                completion?()
            })
        }

        if animatingDifferences {
            updates()
        } else {
            UIView.performWithoutAnimation {
                updates()
            }
        }
    }

    /// Applies a snapshot and returns after the collection view finishes applying the update.
    /// - Parameters:
    ///   - snapshot: The snapshot that replaces the current state.
    ///   - animatingDifferences: A Boolean value that determines whether changes are animated.
    ///   - commitAlongsideUpdates: A closure that commits application-owned models within the collection-view update transaction.
    open func apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
        animatingDifferences: Bool,
        commitAlongsideUpdates: @escaping () -> Void
    ) async {
        await withCheckedContinuation { continuation in
            apply(
                snapshot,
                animatingDifferences: animatingDifferences,
                commitAlongsideUpdates: commitAlongsideUpdates
            ) {
                continuation.resume()
            }
        }
    }

    /// Returns the current index path for an item identifier.
    /// - Parameter id: The item identifier to locate.
    /// - Returns: The item's index path, or `nil` when the identifier is `nil` or is not present in the current snapshot.
    open func indexPath(for id: ItemID?) -> IndexPath? {
        guard let id else {
            return nil
        }
        return state?.itemLocations[id]?.indexPath
    }

    /// Returns the item identifier at an index path in the current snapshot.
    /// - Parameter indexPath: The index path to locate.
    /// - Returns: The item identifier, or `nil` when the index path is not present in the current snapshot.
    open func itemIdentifier(for indexPath: IndexPath) -> ItemID? {
        guard let snapshot,
              indexPath.section < snapshot.sectionIdentifiers.count else {
            return nil
        }
        let sectionID = snapshot.sectionIdentifiers[indexPath.section]
        let itemIdentifiers = snapshot.itemIdentifiers(inSection: sectionID)
        guard indexPath.item < itemIdentifiers.count else {
            return nil
        }
        return itemIdentifiers[indexPath.item]
    }

    /// Returns the number of sections represented by the current snapshot.
    /// - Parameter collectionView: The collection view requesting the information.
    /// - Returns: The number of sections in the current snapshot.
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        snapshot?.sectionIdentifiers.count ?? 0
    }

    /// Returns the number of items in a section represented by the current snapshot.
    /// - Parameters:
    ///   - collectionView: The collection view requesting the information.
    ///   - section: The index of the section.
    /// - Returns: The number of items in the section, or `0` when the section does not exist.
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let snapshot,
              section < snapshot.sectionIdentifiers.count else {
            return 0
        }
        return snapshot.numberOfItems(inSection: snapshot.sectionIdentifiers[section])
    }

    /// Returns the cell provided for the item identifier at an index path.
    /// - Parameters:
    ///   - collectionView: The collection view requesting the cell.
    ///   - indexPath: The index path of the requested cell.
    /// - Returns: The cell returned by the cell provider.
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id: ItemID
        if let reconfiguringIndexPathsToIDs,
           let reconfiguringID = reconfiguringIndexPathsToIDs[indexPath] {
            id = reconfiguringID
        } else if let snapshotID = itemIdentifier(for: indexPath) {
            id = snapshotID
        } else {
            fatalError("Identifier for index path \(indexPath) does not exist.")
        }

        guard let cell = cellProvider(collectionView, indexPath, id) else {
            fatalError("Cell for index path \(indexPath) does not exist.")
        }
        if reconfiguringIndexPathsToIDs?[indexPath] != nil {
            onCellReconfiguration?(cell)
        }
        return cell
    }

    private func applySnapshotUsingReloadData(_ state: State, commitAlongsideUpdates: () -> Void) {
        self.state = state
        commitAlongsideUpdates()
        collectionView.reloadData()
    }

    private nonisolated static func makeUpdatePlan(from oldState: State, to newState: State) -> UpdatePlan {
        let oldSnapshot = oldState.snapshot
        let newSnapshot = newState.snapshot
        let sectionUpdates = makeSectionUpdates(from: oldSnapshot, to: newSnapshot)

        let oldItemIDs = Set(oldState.itemLocations.keys)
        let newItemIDs = Set(newState.itemLocations.keys)
        var insertedItems: [IndexPath] = []
        var deletedItems: [IndexPath] = []
        var movedItems: [ItemMove] = []
        var movedItemIDs: Set<ItemID> = []

        for id in oldItemIDs.subtracting(newItemIDs) {
            guard let oldLocation = oldState.itemLocations[id],
                  !sectionUpdates.deletedIDs.contains(oldLocation.sectionID) else {
                continue
            }
            deletedItems.append(oldLocation.indexPath)
        }

        for id in newItemIDs.subtracting(oldItemIDs) {
            guard let newLocation = newState.itemLocations[id],
                  !sectionUpdates.insertedIDs.contains(newLocation.sectionID) else {
                continue
            }
            insertedItems.append(newLocation.indexPath)
        }

        for id in oldItemIDs.intersection(newItemIDs) {
            guard let oldLocation = oldState.itemLocations[id],
                  let newLocation = newState.itemLocations[id],
                  oldLocation.sectionID != newLocation.sectionID else {
                continue
            }

            if sectionUpdates.deletedIDs.contains(oldLocation.sectionID) {
                if !sectionUpdates.insertedIDs.contains(newLocation.sectionID) {
                    insertedItems.append(newLocation.indexPath)
                }
            } else if sectionUpdates.insertedIDs.contains(newLocation.sectionID) {
                deletedItems.append(oldLocation.indexPath)
            } else {
                movedItems.append(ItemMove(sourceIndexPath: oldLocation.indexPath, destinationIndexPath: newLocation.indexPath))
                movedItemIDs.insert(id)
            }
        }

        let commonSectionIDs = Set(oldSnapshot.sectionIdentifiers).intersection(newSnapshot.sectionIdentifiers)
        for sectionID in commonSectionIDs {
            let itemDifference = newSnapshot.itemIdentifiers(inSection: sectionID)
                .difference(from: oldSnapshot.itemIdentifiers(inSection: sectionID))
                .inferringMoves()
            for update in itemDifference {
                guard case let .remove(_, id, move) = update,
                      move != nil,
                      !movedItemIDs.contains(id),
                      let oldLocation = oldState.itemLocations[id],
                      let newLocation = newState.itemLocations[id],
                      oldLocation.sectionID == newLocation.sectionID else {
                    continue
                }
                movedItems.append(ItemMove(sourceIndexPath: oldLocation.indexPath, destinationIndexPath: newLocation.indexPath))
                movedItemIDs.insert(id)
            }
        }

        let reloadIndexPaths = newSnapshot.reloadedItemIdentifiers.compactMap { id -> IndexPath? in
            guard let oldLocation = oldState.itemLocations[id],
                  let newLocation = newState.itemLocations[id],
                  !sectionUpdates.deletedIDs.contains(oldLocation.sectionID),
                  !sectionUpdates.insertedIDs.contains(newLocation.sectionID) else {
                return nil
            }
            return oldLocation.indexPath
        }
        let reconfiguringIndexPathsToIDs = newSnapshot.reconfiguredItemIdentifiers.reduce(into: [IndexPath: ItemID]()) { result, id in
            guard let oldLocation = oldState.itemLocations[id],
                  let newLocation = newState.itemLocations[id],
                  !sectionUpdates.deletedIDs.contains(oldLocation.sectionID),
                  !sectionUpdates.insertedIDs.contains(newLocation.sectionID) else {
                return
            }
            result[oldLocation.indexPath] = id
        }
        let reconfiguredIndexPaths = Array(reconfiguringIndexPathsToIDs.keys)
        let hasItemUpdates = !insertedItems.isEmpty ||
            !deletedItems.isEmpty ||
            !movedItems.isEmpty ||
            !reloadIndexPaths.isEmpty ||
            !reconfiguredIndexPaths.isEmpty

        return UpdatePlan(
            insertedSections: sectionUpdates.insertedIndexes,
            deletedSections: sectionUpdates.deletedIndexes,
            movedSections: sectionUpdates.moves,
            insertedItems: insertedItems,
            deletedItems: deletedItems,
            movedItems: movedItems,
            reloadIndexPaths: reloadIndexPaths,
            reconfiguredIndexPaths: reconfiguredIndexPaths,
            reconfiguringIndexPathsToIDs: reconfiguringIndexPathsToIDs,
            // UIKit does not guarantee that item updates can safely share a public batch-update transaction with
            // section moves. Supporting that combination requires staging intermediate states, so reload instead.
            requiresReloadData: !newSnapshot.reloadedSectionIdentifiers.isEmpty ||
                (!sectionUpdates.moves.isEmpty && hasItemUpdates)
        )
    }

    private nonisolated static func makeSectionUpdates(
        from oldSnapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
        to newSnapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>
    ) -> SectionUpdates {
        let difference = newSnapshot.sectionIdentifiers
            .difference(from: oldSnapshot.sectionIdentifiers)
            .inferringMoves()
        var insertedIndexes: [Int] = []
        var deletedIndexes: [Int] = []
        var moves: [SectionMove] = []
        var insertedIDs: Set<SectionID> = []
        var deletedIDs: Set<SectionID> = []

        for update in difference {
            switch update {
            case let .remove(offset, id, move):
                if let move {
                    moves.append(SectionMove(sourceIndex: offset, destinationIndex: move))
                } else {
                    deletedIndexes.append(offset)
                    deletedIDs.insert(id)
                }
            case let .insert(offset, id, move):
                if move == nil {
                    insertedIndexes.append(offset)
                    insertedIDs.insert(id)
                }
            }
        }

        return SectionUpdates(
            insertedIndexes: insertedIndexes,
            deletedIndexes: deletedIndexes,
            moves: moves,
            insertedIDs: insertedIDs,
            deletedIDs: deletedIDs
        )
    }
}
