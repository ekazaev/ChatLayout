//
// ChatLayout
// SectionModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct SectionModel {

    let id: UUID

    private(set) var header: ItemModel?

    private(set) var footer: ItemModel?

    private(set) var items: [ItemModel]

    var offsetY: CGFloat = 0

    private unowned var collectionLayout: ChatLayoutRepresentation

    init(id: UUID = UUID(),
         header: ItemModel?,
         footer: ItemModel?,
         items: [ItemModel] = [],
         collectionLayout: ChatLayoutRepresentation) {
        self.id = id
        self.items = items
        self.collectionLayout = collectionLayout
        self.header = header
        self.footer = footer
    }

    mutating func assembleLayout() {
        var offsetY: CGFloat = 0

        if header != nil {
            header?.offsetY = 0
            offsetY += header?.frame.height ?? 0
        }

        for rowIndex in 0..<items.count {
            items[rowIndex].offsetY = offsetY
            offsetY += items[rowIndex].height + collectionLayout.settings.interItemSpacing
        }

        if footer != nil {
            footer?.offsetY = offsetY
        }
    }

    var count: Int {
        return items.count
    }

    var frame: CGRect {
        return CGRect(x: 0, y: offsetY, width: collectionLayout.visibleBounds.width - collectionLayout.settings.additionalInsets.left - collectionLayout.settings.additionalInsets.right, height: height)
    }

    var height: CGFloat {
        if let footer = footer {
            return footer.frame.maxY
        } else {
            guard let lastItem = items.last else {
                return header?.frame.maxY ?? .zero
            }
            return lastItem.locationHeight
        }
    }

    var locationHeight: CGFloat {
        return offsetY + height
    }

    // MARK: To use when its is important to make the correct insertion

    mutating func setAndAssemble(header: ItemModel) {
        guard let oldHeader = self.header else {
            self.header = header
            offsetEverything(below: -1, by: header.height)
            return
        }
        self.header = header
        let heightDiff = header.height - oldHeader.height
        offsetEverything(below: -1, by: heightDiff)
    }

    mutating func setAndAssemble(item: ItemModel, at index: Int) {
        guard index < count else {
            assertionFailure("Internal inconsistency")
            return
        }
        let oldItem = items[index]
        items[index] = item

        let heightDiff = item.height - oldItem.height
        offsetEverything(below: index, by: heightDiff)
    }

    mutating func setAndAssemble(footer: ItemModel) {
        self.footer = footer
    }

    // MARK: Just updaters

    mutating func set(header: ItemModel?) {
        self.header = header
    }

    mutating func set(items: [ItemModel]) {
        self.items = items
    }

    mutating func set(footer: ItemModel?) {
        guard let _ = self.footer, let _ = footer else {
            self.footer = footer
            return
        }
        self.footer = footer
    }

    private mutating func offsetEverything(below index: Int, by heightDiff: CGFloat) {
        guard heightDiff != 0 else {
            return
        }
        if index < items.count - 1 {
            for index in (index + 1)..<items.count {
                items[index].offsetY += heightDiff
            }
        }
        footer?.offsetY += heightDiff
    }

    // MARK: To use only withing process(updateItems:)

    mutating func insert(_ item: ItemModel, at index: Int) {
        guard index <= count else {
            assertionFailure("Internal inconsistency")
            return
        }
        items.insert(item, at: index)
    }

    mutating func replace(_ item: ItemModel, at index: Int) {
        guard index <= count else {
            assertionFailure("Internal inconsistency")
            return
        }
        items[index] = item
    }

    mutating func remove(at index: Int) {
        guard index < count else {
            assertionFailure("Internal inconsistency")
            return
        }
        items.remove(at: index)
    }

    mutating func remove(by itemId: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            assertionFailure("Internal inconsistency")
            return
        }
        items.remove(at: index)
    }

}
