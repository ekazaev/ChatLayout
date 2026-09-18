//
// ChatLayout
// LayoutModel.swift
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
final class LayoutModel<Layout: ChatLayoutRepresentation> {
    private(set) var sections: ContiguousArray<SectionModel<Layout>>

    private unowned var collectionLayout: Layout

    private var sectionIndexByIdentifierCache: [UInt64: Int]?

    private var itemPathByIdentifierCache: [UInt64: ItemPath]?

    private(set) var hasPinnedItems: Bool = false

    init(sections: ContiguousArray<SectionModel<Layout>>, collectionLayout: Layout) {
        self.sections = sections
        self.collectionLayout = collectionLayout
    }

    func assembleLayout() {
        var hasPinnedItems = false
        var offsetY: CGFloat = collectionLayout.settings.additionalInsets.top

        sections.withUnsafeMutableBufferPointer { directlyMutableSections in
            for sectionIndex in 0..<directlyMutableSections.count {
                directlyMutableSections[sectionIndex].offsetY = offsetY
                offsetY += directlyMutableSections[sectionIndex].height + (sectionIndex < directlyMutableSections.count - 1 ? directlyMutableSections[sectionIndex].interSectionSpacing : 0)
                if !hasPinnedItems,
                   directlyMutableSections[sectionIndex].hasPinnedItems {
                    hasPinnedItems = true
                }
            }
        }

        resetCache()
        self.hasPinnedItems = hasPinnedItems
    }

    // MARK: To use when its is important to make the correct insertion

    func setAndAssemble(item: ItemModel, sectionIndex: Int, itemIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }
        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(item: item, at: itemIndex)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
        if !hasPinnedItems,
           sections[sectionIndex].hasPinnedItems {
            hasPinnedItems = true
        }
    }

    func sectionIndex(by sectionId: UInt64) -> Int? {
        if sectionIndexByIdentifierCache == nil {
            sectionIndexByIdentifierCache = makeSectionIndexByIdentifierCache()
        }
        return sectionIndexByIdentifierCache?[sectionId]
    }

    func itemPath(by itemId: UInt64) -> ItemPath? {
        if itemPathByIdentifierCache == nil {
            itemPathByIdentifierCache = makeItemPathByIdentifierCache()
        }
        return itemPathByIdentifierCache?[itemId]
    }

    func findPinnedItemBefore(_ indexPath: IndexPath, pinningType: ChatItemPinningType) -> IndexPath? {
        for sectionIndex in (0...indexPath.section).reversed() {
            let section = sections[sectionIndex]
            guard let pinnedIndexes = section.pinnedIndexes[pinningType] else {
                continue
            }
            for stickyItemIndex in (0..<pinnedIndexes.count).reversed() {
                let index = pinnedIndexes[stickyItemIndex]

                if sectionIndex == indexPath.section, index < indexPath.item {
                    return IndexPath(item: index, section: sectionIndex)
                }

                if sectionIndex < indexPath.section {
                    return IndexPath(item: index, section: sectionIndex)
                }
            }
        }
        return nil
    }

    func findPinnedItemAfter(_ indexPath: IndexPath, pinningType: ChatItemPinningType) -> IndexPath? {
        for sectionIndex in indexPath.section..<sections.count {
            let section = sections[sectionIndex]
            guard let pinnedIndexes = section.pinnedIndexes[pinningType] else {
                continue
            }
            for stickyItemIndex in 0..<pinnedIndexes.count {
                let index = pinnedIndexes[stickyItemIndex]

                if sectionIndex == indexPath.section, index > indexPath.item {
                    return IndexPath(item: index, section: sectionIndex)
                }

                if sectionIndex > indexPath.section {
                    return IndexPath(item: index, section: sectionIndex)
                }
            }
        }
        return nil
    }

    // MARK: To use only within process(updateItems:)

    func insertSection(_ section: SectionModel<Layout>, at sectionIndex: Int) {
        var sections = sections
        guard sectionIndex <= sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }

        sections.insert(section, at: sectionIndex)
        self.sections = sections
        resetCache()
    }

    func removeSection(by sectionIdentifier: UInt64) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionIdentifier }) else {
            assertionFailure("Incorrect section identifier.")
            return
        }
        sections.remove(at: sectionIndex)
        resetCache()
    }

    func removeSection(for sectionIndex: Int) {
        sections.remove(at: sectionIndex)
        resetCache()
    }

    func insertItem(_ item: ItemModel, at indexPath: IndexPath) {
        sections[indexPath.section].insert(item, at: indexPath.item)
        resetCache()
    }

    func replaceItem(_ item: ItemModel, at indexPath: IndexPath) {
        sections[indexPath.section].replace(item, at: indexPath.item)
        resetCache()
    }

    func removeItem(by itemId: UInt64) {
        var itemPath: ItemPath?
        for (sectionIndex, section) in sections.enumerated() {
            if let itemIndex = section.items.firstIndex(where: { $0.id == itemId }) {
                itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                break
            }
        }
        guard let path = itemPath else {
            assertionFailure("Incorrect item identifier.")
            return
        }
        sections[path.section].remove(at: path.item)
        resetCache()
    }

    private func resetCache() {
        itemPathByIdentifierCache = nil
        sectionIndexByIdentifierCache = nil
    }

    private func offsetEverything(below index: Int, by heightDiff: CGFloat) {
        guard heightDiff != 0 else {
            return
        }
        if index < sections.count &- 1 {
            let nextIndex = index &+ 1
            sections.withUnsafeMutableBufferPointer { directlyMutableSections in
                for internalIndex in 0..<(directlyMutableSections.count &- nextIndex) {
                    directlyMutableSections[internalIndex &+ nextIndex].offsetY += heightDiff
                }
            }
        }
    }

    private func makeSectionIndexByIdentifierCache() -> [UInt64: Int] {
        var cache = [UInt64: Int](minimumCapacity: sections.count)
        for sectionIndex in 0..<sections.count {
            cache[sections[sectionIndex].id] = sectionIndex
        }
        return cache
    }

    private func makeItemPathByIdentifierCache() -> [UInt64: ItemPath] {
        let capacity = sections.reduce(into: 0) { $0 += $1.items.count }
        var cache = [UInt64: ItemPath](minimumCapacity: capacity)
        for sectionIndex in 0..<sections.count {
            for itemIndex in 0..<sections[sectionIndex].items.count {
                let itemId = sections[sectionIndex].items[itemIndex].id
                cache[itemId] = ItemPath(item: itemIndex, section: sectionIndex)
            }
        }
        return cache
    }
}
