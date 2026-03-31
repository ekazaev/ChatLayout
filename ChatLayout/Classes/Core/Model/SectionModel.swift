//
// ChatLayout
// SectionModel.swift
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

@MainActor
struct SectionModel<Layout: ChatLayoutRepresentation> {
    let id: UUID

    let interSectionSpacing: CGFloat

    private(set) var items: ContiguousArray<ItemModel>

    var hasPinnedItems: Bool {
        !pinnedIndexes.isEmpty
    }

    private(set) var pinnedIndexes = [ChatItemPinningType: ContiguousArray<Int>]()

    var offsetY: CGFloat = 0

    private unowned var collectionLayout: Layout

    var frame: CGRect {
        let additionalInsets = collectionLayout.settings.additionalInsets
        return CGRect(
            x: 0,
            y: offsetY,
            width: collectionLayout.visibleBounds.width - additionalInsets.left - additionalInsets.right,
            height: height
        )
    }

    var height: CGFloat {
        guard let lastItem = items.last else {
            return .zero
        }
        return lastItem.frame.maxY
    }

    var locationHeight: CGFloat {
        offsetY + height
    }

    init(
        id: UUID = UUID(),
        interSectionSpacing: CGFloat,
        items: ContiguousArray<ItemModel> = [],
        collectionLayout: Layout
    ) {
        self.id = id
        self.interSectionSpacing = interSectionSpacing
        self.items = items
        self.collectionLayout = collectionLayout
    }

    mutating func assembleLayout() {
        var offsetY: CGFloat = 0
        pinnedIndexes = [:]

        items.withUnsafeMutableBufferPointer { directlyMutableItems in
            for rowIndex in 0..<directlyMutableItems.count {
                directlyMutableItems[rowIndex].offsetY = offsetY
                let offset: CGFloat = rowIndex < directlyMutableItems.count - 1 ? directlyMutableItems[rowIndex].interItemSpacing : 0
                offsetY += directlyMutableItems[rowIndex].size.height + offset
                if let pinningType = directlyMutableItems[rowIndex].pinningType {
                    pinnedIndexes[pinningType, default: ContiguousArray()].append(rowIndex)
                }
            }
        }
    }

    mutating func setAndAssemble(item: ItemModel, at index: Int) {
        guard index < items.count else {
            assertionFailure("Incorrect item index.")
            return
        }
        let oldItem = items[index]
        #if DEBUG
        if item.id != oldItem.id {
            assertionFailure("Internal inconsistency.")
        }
        #endif
        items[index] = item

        if let pinningType = item.pinningType {
            if var pinnedBehavourIndexes = pinnedIndexes[pinningType] {
                pinnedBehavourIndexes.append(index)
                pinnedIndexes[pinningType] = ContiguousArray(pinnedBehavourIndexes.sorted())
            }
        } else {
            let localPinnedIndexes = pinnedIndexes
            localPinnedIndexes.forEach { key, value in
                if let index = value.firstIndex(of: index) {
                    var value = value
                    value.remove(at: index)
                    pinnedIndexes[key] = value
                }
            }
        }

        let heightDiff = item.size.height - oldItem.size.height
        offsetEverything(below: index, by: heightDiff)
    }

    mutating func set(items: ContiguousArray<ItemModel>) {
        self.items = items
    }

    private mutating func offsetEverything(below index: Int, by heightDiff: CGFloat) {
        guard heightDiff != 0 else {
            return
        }
        if index < items.count &- 1 {
            let nextIndex = index &+ 1
            items.withUnsafeMutableBufferPointer { directlyMutableItems in
                nonisolated(unsafe) let directlyMutableItems = directlyMutableItems
                DispatchQueue.concurrentPerform(iterations: directlyMutableItems.count &- nextIndex) { internalIndex in
                    directlyMutableItems[internalIndex &+ nextIndex].offsetY += heightDiff
                }
            }
        }
    }

    // MARK: To use only within process(updateItems:)

    mutating func insert(_ item: ItemModel, at index: Int) {
        guard index <= items.count else {
            assertionFailure("Incorrect item index.")
            return
        }
        items.insert(item, at: index)
    }

    mutating func replace(_ item: ItemModel, at index: Int) {
        guard index <= items.count else {
            assertionFailure("Incorrect item index.")
            return
        }
        items[index] = item
    }

    mutating func remove(at index: Int) {
        guard index < items.count else {
            assertionFailure("Incorrect item index.")
            return
        }
        items.remove(at: index)
    }
}
