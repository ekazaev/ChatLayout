//
// ChatLayout
// LayoutModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2023.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

final class LayoutModel<Layout: ChatLayoutRepresentation> {

    private struct ItemUUIDKey: Hashable {

        let kind: ItemKind

        let id: UUID

    }

    private(set) var sections: ContiguousArray<SectionModel<Layout>>

    private unowned var collectionLayout: Layout

    private var sectionIndexByIdentifierCache: [UUID: Int]?

    private var itemPathByIdentifierCache: [ItemUUIDKey: ItemPath]?

    init(sections: ContiguousArray<SectionModel<Layout>>, collectionLayout: Layout) {
        self.sections = sections
        self.collectionLayout = collectionLayout
    }

    func assembleLayout() {
        var offsetY: CGFloat = collectionLayout.settings.additionalInsets.top

        var sectionIndexByIdentifierCache = [UUID: Int](minimumCapacity: sections.count)
        let capacity = sections.reduce(into: 0) { $0 += $1.items.count }
        var itemPathByIdentifierCache = [ItemUUIDKey: ItemPath](minimumCapacity: capacity)

        sections.withUnsafeMutableBufferPointer { directlyMutableSections in
            for sectionIndex in 0..<directlyMutableSections.count {
                sectionIndexByIdentifierCache[directlyMutableSections[sectionIndex].id] = sectionIndex
                directlyMutableSections[sectionIndex].offsetY = offsetY
                offsetY += directlyMutableSections[sectionIndex].height + directlyMutableSections[sectionIndex].interSectionSpacing
                if let header = directlyMutableSections[sectionIndex].header {
                    let key = ItemUUIDKey(kind: .header, id: header.id)
                    itemPathByIdentifierCache[key] = ItemPath(item: 0, section: sectionIndex)
                }
                for itemIndex in 0..<directlyMutableSections[sectionIndex].items.count {
                    let key = ItemUUIDKey(kind: .cell, id: directlyMutableSections[sectionIndex].items[itemIndex].id)
                    itemPathByIdentifierCache[key] = ItemPath(item: itemIndex, section: sectionIndex)
                }
                if let footer = directlyMutableSections[sectionIndex].footer {
                    let key = ItemUUIDKey(kind: .footer, id: footer.id)
                    itemPathByIdentifierCache[key] = ItemPath(item: 0, section: sectionIndex)
                }
            }
        }

        self.itemPathByIdentifierCache = itemPathByIdentifierCache
        self.sectionIndexByIdentifierCache = sectionIndexByIdentifierCache
    }

    // MARK: To use when its is important to make the correct insertion

    func setAndAssemble(header: ItemModel, sectionIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }

        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(header: header)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    func setAndAssemble(item: ItemModel, sectionIndex: Int, itemIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }
        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(item: item, at: itemIndex)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    func setAndAssemble(footer: ItemModel, sectionIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }
        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(footer: footer)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    func sectionIndex(by sectionId: UUID) -> Int? {
        guard let sectionIndexByIdentifierCache else {
            assertionFailure("Internal inconsistency. Cache is not prepared.")
            return sections.firstIndex(where: { $0.id == sectionId })
        }
        return sectionIndexByIdentifierCache[sectionId]
    }

    func itemPath(by itemId: UUID, kind: ItemKind) -> ItemPath? {
        guard let itemPathByIdentifierCache else {
            assertionFailure("Internal inconsistency. Cache is not prepared.")
            for (sectionIndex, section) in sections.enumerated() {
                switch kind {
                case .header:
                    if itemId == section.header?.id {
                        return ItemPath(item: 0, section: sectionIndex)
                    }
                case .footer:
                    if itemId == section.footer?.id {
                        return ItemPath(item: 0, section: sectionIndex)
                    }
                case .cell:
                    if let itemIndex = section.items.firstIndex(where: { $0.id == itemId }) {
                        return ItemPath(item: itemIndex, section: sectionIndex)
                    }
                }
            }
            return nil
        }
        return itemPathByIdentifierCache[ItemUUIDKey(kind: kind, id: itemId)]
    }

    private func offsetEverything(below index: Int, by heightDiff: CGFloat) {
        guard heightDiff != 0 else {
            return
        }
        if index < sections.count &- 1 {
            let nextIndex = index &+ 1
            sections.withUnsafeMutableBufferPointer { directlyMutableSections in
                DispatchQueue.concurrentPerform(iterations: directlyMutableSections.count &- nextIndex) { internalIndex in
                    directlyMutableSections[internalIndex &+ nextIndex].offsetY += heightDiff
                }
            }
        }
    }

    // MARK: To use only withing process(updateItems:)

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

    func removeSection(by sectionIdentifier: UUID) {
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

    func removeItem(by itemId: UUID) {
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

}
