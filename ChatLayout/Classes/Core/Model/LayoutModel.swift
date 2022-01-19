//
// ChatLayout
// LayoutModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct LayoutModel {

    private struct ItemUUIDKey: Hashable {

        let kind: ItemKind

        let id: UUID

    }

    private(set) var sections: [SectionModel]

    private unowned var collectionLayout: ChatLayoutRepresentation

    private var sectionIndexByIdentifierCache: [UUID: Int]?

    private var itemPathByIdentifierCache: [ItemUUIDKey: ItemPath]?

    init(sections: [SectionModel], collectionLayout: ChatLayoutRepresentation) {
        self.sections = sections
        self.collectionLayout = collectionLayout
    }

    mutating func assembleLayout() {
        var offset: CGFloat = collectionLayout.settings.additionalInsets.top

        var sectionIndexByIdentifierCache = [UUID: Int](minimumCapacity: sections.count)
        var itemPathByIdentifierCache = [ItemUUIDKey: ItemPath]()

        for sectionIndex in 0..<sections.count {
            sectionIndexByIdentifierCache[sections[sectionIndex].id] = sectionIndex
            sections[sectionIndex].offsetY = offset
            offset += sections[sectionIndex].height + collectionLayout.settings.interSectionSpacing
            if let header = sections[sectionIndex].header {
                itemPathByIdentifierCache[ItemUUIDKey(kind: .header, id: header.id)] = ItemPath(item: 0, section: sectionIndex)
            }
            for itemIndex in 0..<sections[sectionIndex].items.count {
                itemPathByIdentifierCache[ItemUUIDKey(kind: .cell, id: sections[sectionIndex].items[itemIndex].id)] = ItemPath(item: itemIndex, section: sectionIndex)
            }
            if let footer = sections[sectionIndex].footer {
                itemPathByIdentifierCache[ItemUUIDKey(kind: .footer, id: footer.id)] = ItemPath(item: 0, section: sectionIndex)
            }
        }
        self.itemPathByIdentifierCache = itemPathByIdentifierCache
        self.sectionIndexByIdentifierCache = sectionIndexByIdentifierCache
    }

    // MARK: To use when its is important to make the correct insertion

    mutating func setAndAssemble(header: ItemModel, sectionIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }

        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(header: header)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    mutating func setAndAssemble(item: ItemModel, sectionIndex: Int, itemIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }
        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(item: item, at: itemIndex)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    mutating func setAndAssemble(footer: ItemModel, sectionIndex: Int) {
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
        guard let sectionIndexByIdentifierCache = sectionIndexByIdentifierCache else {
            assertionFailure("Internal inconsistency. Cache is not prepared.")
            return sections.firstIndex(where: { $0.id == sectionId })
        }
        return sectionIndexByIdentifierCache[sectionId]
    }

    func itemPath(by itemId: UUID, kind: ItemKind) -> ItemPath? {
        guard let itemPathByIdentifierCache = itemPathByIdentifierCache else {
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

    private mutating func offsetEverything(below index: Int, by heightDiff: CGFloat) {
        guard heightDiff != 0 else {
            return
        }
        if index < sections.count - 1 {
            for index in (index + 1)..<sections.count {
                sections[index].offsetY += heightDiff
            }
        }
    }

    // MARK: To use only withing process(updateItems:)

    mutating func insertSection(_ section: SectionModel, at sectionIndex: Int) {
        var sections = self.sections
        guard sectionIndex <= sections.count else {
            assertionFailure("Incorrect section index.")
            return
        }

        sections.insert(section, at: sectionIndex)
        self.sections = sections
        resetCache()
    }

    mutating func removeSection(by sectionIdentifier: UUID) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionIdentifier }) else {
            assertionFailure("Incorrect section identifier.")
            return
        }
        sections.remove(at: sectionIndex)
        resetCache()
    }

    mutating func removeSection(for sectionIndex: Int) {
        sections.remove(at: sectionIndex)
        resetCache()
    }

    mutating func insertItem(_ item: ItemModel, at indexPath: IndexPath) {
        sections[indexPath.section].insert(item, at: indexPath.item)
        resetCache()
    }

    mutating func replaceItem(_ item: ItemModel, at indexPath: IndexPath) {
        sections[indexPath.section].replace(item, at: indexPath.item)
        resetCache()
    }

    mutating func removeItem(by itemId: UUID) {
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

    private mutating func resetCache() {
        itemPathByIdentifierCache = nil
        sectionIndexByIdentifierCache = nil
    }

}
