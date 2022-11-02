//
// ChatLayout
// SectionModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

struct SectionModel<Layout: ChatLayoutRepresentation> {

    let id: UUID

    private(set) var header: ItemModel?

    private(set) var footer: ItemModel?

    private(set) var items: ContiguousArray<ItemModel>

    var offsetY: CGFloat = 0

    private unowned var collectionLayout: Layout

    var frame: CGRect {
        let additionalInsets = collectionLayout.settings.additionalInsets
        return CGRect(x: 0,
                      y: offsetY,
                      width: collectionLayout.visibleBounds.width - additionalInsets.left - additionalInsets.right,
                      height: height)
    }

    var height: CGFloat {
        if let footer = footer {
            return footer.frame.maxY
        } else {
            guard let lastItem = items.last else {
                return header?.frame.maxY ?? .zero
            }
            return lastItem.frame.maxY
        }
    }

    var locationHeight: CGFloat {
        offsetY + height
    }

    init(id: UUID = UUID(),
         header: ItemModel?,
         footer: ItemModel?,
         items: ContiguousArray<ItemModel> = [],
         collectionLayout: Layout) {
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

        items.withUnsafeMutableBufferPointer { directlyMutableItems in
            for rowIndex in 0..<directlyMutableItems.count {
                directlyMutableItems[rowIndex].offsetY = offsetY
                offsetY += directlyMutableItems[rowIndex].size.height + collectionLayout.settings.interItemSpacing
            }
        }

        if footer != nil {
            footer?.offsetY = offsetY
        }
    }

    // MARK: To use when its is important to make the correct insertion

    mutating func setAndAssemble(header: ItemModel) {
        guard let oldHeader = self.header else {
            self.header = header
            offsetEverything(below: -1, by: header.size.height)
            return
        }
        #if DEBUG
        if header.id != oldHeader.id {
            assertionFailure("Internal inconsistency.")
        }
        #endif
        self.header = header
        let heightDiff = header.size.height - oldHeader.size.height
        offsetEverything(below: -1, by: heightDiff)
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

        let heightDiff = item.size.height - oldItem.size.height
        offsetEverything(below: index, by: heightDiff)
    }

    mutating func setAndAssemble(footer: ItemModel) {
        #if DEBUG
        if let oldFooter = self.footer,
           footer.id != oldFooter.id {
            assertionFailure("Internal inconsistency.")
        }
        #endif
        self.footer = footer
    }

    // MARK: Just updaters

    mutating func set(header: ItemModel?) {
        self.header = header
    }

    mutating func set(items: ContiguousArray<ItemModel>) {
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
        if index < items.count &- 1 {
            let nextIndex = index &+ 1
            items.withUnsafeMutableBufferPointer { directlyMutableItems in
                DispatchQueue.concurrentPerform(iterations: directlyMutableItems.count &- nextIndex) { internalIndex in
                    directlyMutableItems[internalIndex &+ nextIndex].offsetY += heightDiff
                }
            }
        }
        footer?.offsetY += heightDiff
    }

    // MARK: To use only withing process(updateItems:)

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
