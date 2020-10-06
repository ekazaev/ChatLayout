//
// ChatLayout
// LayoutModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct LayoutModel {

    var sections: [SectionModel]

    private unowned var collectionLayout: ChatLayoutRepresentation

    init(sections: [SectionModel], collectionLayout: ChatLayoutRepresentation) {
        self.sections = sections
        self.collectionLayout = collectionLayout
    }

    mutating func assembleLayout() {
        var offset: CGFloat = collectionLayout.settings.additionalInsets.top

        for index in 0..<sections.count {
            sections[index].offsetY = offset
            offset += sections[index].height + collectionLayout.settings.interSectionSpacing
        }
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
    }

    mutating func removeSection(by sectionIdentifier: UUID) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionIdentifier }) else {
            assertionFailure("Internal inconsistency")
            return
        }
        sections.remove(at: sectionIndex)
    }

    mutating func removeSection(for sectionIndex: Int) {
        sections.remove(at: sectionIndex)
    }

    mutating func insertItem(_ item: ItemModel, at indexPath: IndexPath) {
        sections[indexPath.section].insert(item, at: indexPath.item)
    }

    mutating func replaceItem(_ item: ItemModel, at indexPath: IndexPath) {
        sections[indexPath.section].replace(item, at: indexPath.item)
    }

    mutating func removeItem(by itemId: UUID) {
        guard let sectionIndex = sections.firstIndex(where: { $0.items.firstIndex(where: { $0.id == itemId }) != nil }) else {
            assertionFailure("Internal inconsistency")
            return
        }
        sections[sectionIndex].remove(by: itemId)
    }

}
