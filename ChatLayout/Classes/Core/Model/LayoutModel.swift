//
// ChatLayout
// LayoutModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2021.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct LayoutModel {

    private(set) var sections: [SectionModel]

    private unowned var collectionLayout: ChatLayoutRepresentation

    private var sectionIndexByIdentifierCache: [UUID: Int]?

    private var itemPathByIdentifierCache: [UUID: ItemPath]?

    init(sections: [SectionModel], collectionLayout: ChatLayoutRepresentation) {
        self.sections = sections
        self.collectionLayout = collectionLayout
    }

    mutating func assembleLayout() {
        var offset: CGFloat = collectionLayout.settings.additionalInsets.top

        var sectionIndexByIdentifierCache = [UUID: Int](minimumCapacity: sections.count)
        var itemPathByIdentifierCache = [UUID: ItemPath]()

        for sectionIndex in 0..<sections.count {
            sectionIndexByIdentifierCache[sections[sectionIndex].id] = sectionIndex
            sections[sectionIndex].offsetY = offset
            offset += sections[sectionIndex].height + collectionLayout.settings.interSectionSpacing
            for itemIndex in 0..<sections[sectionIndex].items.count {
                itemPathByIdentifierCache[sections[sectionIndex].items[itemIndex].id] = ItemPath(item: itemIndex, section: sectionIndex)
            }
        }
        self.itemPathByIdentifierCache = itemPathByIdentifierCache
        self.sectionIndexByIdentifierCache = sectionIndexByIdentifierCache
    }

    // MARK: To use when its is important to make the correct insertion

    mutating func setAndAssemble(header: ItemModel, sectionIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Internal inconsistency")
            return
        }

        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(header: header)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    mutating func setAndAssemble(item: ItemModel, sectionIndex: Int, itemIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Internal inconsistency")
            return
        }
        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(item: item, at: itemIndex)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    mutating func setAndAssemble(footer: ItemModel, sectionIndex: Int) {
        guard sectionIndex < sections.count else {
            assertionFailure("Internal inconsistency")
            return
        }
        let oldSection = sections[sectionIndex]
        sections[sectionIndex].setAndAssemble(footer: footer)
        let heightDiff = sections[sectionIndex].height - oldSection.height
        offsetEverything(below: sectionIndex, by: heightDiff)
    }

    func sectionIndex(by sectionId: UUID) -> Int? {
        guard let sectionIndexByIdentifierCache = sectionIndexByIdentifierCache else {
            assertionFailure("Internal inconsistency")
            return sections.firstIndex(where: { $0.id == sectionId })
        }
        return sectionIndexByIdentifierCache[sectionId]
    }

    func itemPath(by itemId: UUID) -> ItemPath? {
        guard let itemPathByIdentifierCache = itemPathByIdentifierCache else {
            assertionFailure("Internal inconsistency")
            for (sectionIndex, section) in sections.enumerated() {
                if let itemIndex = section.items.firstIndex(where: { $0.id == itemId })  {
                    return ItemPath(item: itemIndex, section: sectionIndex)
                }
            }
            return nil
        }
        return itemPathByIdentifierCache[itemId]
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
            assertionFailure("Internal inconsistency")
            return
        }

        sections.insert(section, at: sectionIndex)
        self.sections = sections
        resetCache()
    }

    mutating func removeSection(by sectionIdentifier: UUID) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionIdentifier }) else {
            assertionFailure("Internal inconsistency")
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
        guard let sectionIndex = sections.firstIndex(where: { $0.items.firstIndex(where: { $0.id == itemId }) != nil }) else {
            assertionFailure("Internal inconsistency")
            return
        }
        sections[sectionIndex].remove(by: itemId)
        resetCache()
    }

    private mutating func resetCache() {
        itemPathByIdentifierCache = nil
        sectionIndexByIdentifierCache = nil
    }

}
