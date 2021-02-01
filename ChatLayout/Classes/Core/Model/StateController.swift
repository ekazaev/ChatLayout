//
// ChatLayout
// StateController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2021.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// This protocol exists only to serve an ability to unit test `StateController`.
protocol ChatLayoutRepresentation: AnyObject {

    var settings: ChatLayoutSettings { get }

    var viewSize: CGSize { get }

    var visibleBounds: CGRect { get }

    var layoutFrame: CGRect { get }

    var adjustedContentInset: UIEdgeInsets { get }

    var keepContentOffsetAtBottomOnBatchUpdates: Bool { get }

    func numberOfItems(in section: Int) -> Int

    func configuration(for element: ItemKind, at itemPath: ItemPath) -> ItemModel.Configuration

    func shouldPresentHeader(at sectionIndex: Int) -> Bool

    func shouldPresentFooter(at sectionIndex: Int) -> Bool

}

final class StateController {

    private enum CompensatingAction {
        case insert
        case delete
        case frameUpdate(previousFrame: CGRect, newFrame: CGRect)
    }

    // This thing exists here as `UICollectionView` calls `targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint)` only once at the
    // beginning of the animated updates. But we must compensate the other changes that happened during the update.
    var batchUpdateCompensatingOffset: CGFloat = 0

    var proposedCompensatingOffset: CGFloat = 0

    var totalProposedCompensatingOffset: CGFloat = 0

    var isAnimatedBoundsChange = false

    private(set) var storage: [ModelState: LayoutModel]

    private(set) var reloadedIndexes: Set<IndexPath> = []

    private(set) var insertedIndexes: Set<IndexPath> = []

    private(set) var movedIndexes: Set<IndexPath> = []

    private(set) var deletedIndexes: Set<IndexPath> = []

    private(set) var reloadedSectionsIndexes: Set<Int> = []

    private(set) var insertedSectionsIndexes: Set<Int> = []

    private(set) var deletedSectionsIndexes: Set<Int> = []

    private(set) var movedSectionsIndexes: Set<Int> = []

    private var cachedAttributesState: (rect: CGRect, attributes: [ChatLayoutAttributes])?

    private var cachedAttributeObjects = [ModelState: [ItemKind: [ItemPath: ChatLayoutAttributes]]]()

    private unowned var layoutRepresentation: ChatLayoutRepresentation

    init(layoutRepresentation: ChatLayoutRepresentation) {
        self.layoutRepresentation = layoutRepresentation
        self.storage = [.beforeUpdate: LayoutModel(sections: [], collectionLayout: self.layoutRepresentation)]
        resetCachedAttributeObjects()
    }

    func set(_ sections: [SectionModel], at state: ModelState) {
        var layoutModel = LayoutModel(sections: sections, collectionLayout: layoutRepresentation)
        layoutModel.assembleLayout()
        storage[state] = layoutModel
    }

    func contentHeight(at state: ModelState) -> CGFloat {
        guard let locationHeight = storage[state]?.sections.last?.locationHeight else {
            return 0
        }
        return locationHeight + layoutRepresentation.settings.additionalInsets.bottom
    }

    func layoutAttributesForElements(in rect: CGRect,
                                     state: ModelState,
                                     ignoreCache: Bool = false) -> [ChatLayoutAttributes] {
        if !ignoreCache,
            let cachedAttributesState = cachedAttributesState,
            cachedAttributesState.rect.contains(rect) {
            return cachedAttributesState.attributes.filter { $0.frame.intersects(rect) }
        } else {
            let totalRect = rect.inset(by: UIEdgeInsets(top: -rect.height / 2, left: -rect.width / 2, bottom: -rect.height / 2, right: -rect.width / 2))
            let attributes = allAttributes(at: state, visibleRect: totalRect)
            if !ignoreCache {
                cachedAttributesState = (rect: totalRect, attributes: attributes)
            }
            let visibleAttributes = attributes.filter { $0.frame.intersects(rect) }
            return visibleAttributes
        }
    }

    func resetCachedAttributes() {
        cachedAttributesState = nil
    }

    func resetCachedAttributeObjects() {
        ModelState.allCases.forEach { state in
            resetCachedAttributeObjects(at: state)
        }
    }

    private func resetCachedAttributeObjects(at state: ModelState) {
        cachedAttributeObjects[state] = [:]
        ItemKind.allCases.forEach { kind in
            cachedAttributeObjects[state]?[kind] = [:]
        }
    }

    func itemAttributes(for itemPath: ItemPath,
                        kind: ItemKind,
                        predefinedFrame: CGRect? = nil,
                        at state: ModelState) -> ChatLayoutAttributes? {
        let attributes: ChatLayoutAttributes
        let itemIndexPath = itemPath.indexPath
        switch kind {
        case .header:
            guard itemPath.section < layout(at: state).sections.count,
                itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let headerFrame = predefinedFrame ?? itemFrame(for: itemPath, kind: kind, at: state, isFinal: true),
                let item = item(for: itemPath, kind: kind, at: state) else {
                return nil
            }
            if let cachedAttributes = cachedAttributeObjects[state]?[.header]?[itemPath] {
                attributes = cachedAttributes
            } else {
                attributes = ChatLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: itemIndexPath)
                cachedAttributeObjects[state]?[.header]?[itemPath] = attributes
            }
            #if DEBUG
            attributes.id = item.id
            #endif
            attributes.frame = headerFrame
            attributes.indexPath = itemIndexPath
            attributes.zIndex = 10
            attributes.alignment = item.alignment
        case .footer:
            guard itemPath.section < layout(at: state).sections.count,
                itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let footerFrame = predefinedFrame ?? itemFrame(for: itemPath, kind: kind, at: state, isFinal: true),
                let item = item(for: itemPath, kind: kind, at: state) else {
                return nil
            }
            if let cachedAttributes = cachedAttributeObjects[state]?[.footer]?[itemPath] {
                attributes = cachedAttributes
            } else {
                attributes = ChatLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: itemIndexPath)
                cachedAttributeObjects[state]?[.footer]?[itemPath] = attributes
            }
            #if DEBUG
            attributes.id = item.id
            #endif
            attributes.frame = footerFrame
            attributes.indexPath = itemIndexPath
            attributes.zIndex = 10
            attributes.alignment = item.alignment
        case .cell:
            guard itemPath.section < layout(at: state).sections.count,
                itemPath.item < layout(at: state).sections[itemPath.section].items.count else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let itemFrame = predefinedFrame ?? itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true),
                let item = item(for: itemPath, kind: kind, at: state) else {
                return nil
            }
            if let cachedAttributes = cachedAttributeObjects[state]?[.cell]?[itemPath] {
                attributes = cachedAttributes
            } else {
                attributes = ChatLayoutAttributes(forCellWith: itemIndexPath)
                cachedAttributeObjects[state]?[.cell]?[itemPath] = attributes
            }
            #if DEBUG
            attributes.id = item.id
            #endif
            attributes.frame = itemFrame
            attributes.indexPath = itemIndexPath
            attributes.zIndex = 0
            attributes.alignment = item.alignment
        }
        attributes.viewSize = layoutRepresentation.viewSize
        attributes.adjustedContentInsets = layoutRepresentation.adjustedContentInset
        attributes.visibleBoundsSize = layoutRepresentation.visibleBounds.size
        attributes.layoutFrame = layoutRepresentation.layoutFrame
        attributes.additionalInsets = layoutRepresentation.settings.additionalInsets
        return attributes
    }

    func itemFrame(for itemPath: ItemPath, kind: ItemKind, at state: ModelState, isFinal: Bool = false) -> CGRect? {
        guard itemPath.section < layout(at: state).sections.count else {
            return nil
        }
        guard let item = self.item(for: itemPath, kind: kind, at: state) else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }

        let section = layout(at: state).sections[itemPath.section]
        var itemFrame = item.frame
        let dx: CGFloat
        let visibleBounds = layoutRepresentation.visibleBounds
        let additionalInsets = layoutRepresentation.settings.additionalInsets

        switch item.alignment {
        case .leading:
            dx = additionalInsets.left
        case .trailing:
            dx = visibleBounds.size.width - itemFrame.width - additionalInsets.right
        case .center:
            let availableWidth = visibleBounds.size.width - additionalInsets.right - additionalInsets.left
            dx = additionalInsets.left + availableWidth / 2 - itemFrame.width / 2
        case .fullWidth:
            dx = additionalInsets.left
            itemFrame.size.width = layoutRepresentation.layoutFrame.size.width
        }

        itemFrame = itemFrame.offsetBy(dx: dx, dy: section.offsetY)
        if isFinal {
            itemFrame = offsetByCompensation(frame: itemFrame, at: itemPath, for: state, backward: true)
        }
        return itemFrame
    }

    func itemPath(by itemId: UUID, at state: ModelState) -> ItemPath? {
        return layout(at: state).itemPath(by: itemId)
    }

    func sectionIdentifier(for index: Int, at state: ModelState) -> UUID? {
        guard index < layout(at: state).sections.count else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }
        return layout(at: state).sections[index].id
    }

    func sectionIndex(for sectionIdentifier: UUID, at state: ModelState) -> Int? {
        guard let sectionIndex = layout(at: state).sectionIndex(by: sectionIdentifier) else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }
        return sectionIndex
    }

    func section(at index: Int, at state: ModelState) -> SectionModel {
        guard index < layout(at: state).sections.count else {
            preconditionFailure("Section index \(index) is bigger than the amount of sections \(layout(at: state).sections.count)")
        }
        return layout(at: state).sections[index]
    }

    func itemIdentifier(for itemPath: ItemPath, kind: ItemKind, at state: ModelState) -> UUID? {
        guard itemPath.section < layout(at: state).sections.count else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }
        let sectionModel = layout(at: state).sections[itemPath.section]
        switch kind {
        case .cell:
            guard itemPath.item < layout(at: state).sections[itemPath.section].items.count else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            let rowModel = sectionModel.items[itemPath.item]
            return rowModel.id
        case .header, .footer:
            guard let item = item(for: ItemPath(item: 0, section: itemPath.section), kind: kind, at: state) else {
                return nil
            }
            return item.id
        }

    }

    func numberOfSections(at state: ModelState) -> Int {
        return layout(at: state).sections.count
    }

    func numberOfItems(in sectionIndex: Int, at state: ModelState) -> Int {
        return layout(at: state).sections[sectionIndex].items.count
    }

    func item(for itemPath: ItemPath, kind: ItemKind, at state: ModelState) -> ItemModel? {
        switch kind {
        case .header:
            guard itemPath.section < layout(at: state).sections.count,
                itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let header = layout(at: state).sections[itemPath.section].header else {
                return nil
            }
            return header
        case .footer:
            guard itemPath.section < layout(at: state).sections.count,
                itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let footer = layout(at: state).sections[itemPath.section].footer else {
                return nil
            }
            return footer
        case .cell:
            guard itemPath.section < layout(at: state).sections.count,
                itemPath.item < layout(at: state).sections[itemPath.section].count else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            return layout(at: state).sections[itemPath.section].items[itemPath.item]
        }
    }

    func update(preferredSize: CGSize, for itemPath: ItemPath, kind: ItemKind, at state: ModelState) {
        guard var item = item(for: itemPath, kind: kind, at: state) else {
            assertionFailure("Internal inconsistency")
            return
        }
        var layout = self.layout(at: state)
        let previousFrame = item.frame
        cachedAttributesState = nil
        item.calculatedSize = preferredSize
        item.calculatedOnce = true

        switch kind {
        case .header:
            layout.setAndAssemble(header: item, sectionIndex: itemPath.section)
        case .footer:
            layout.setAndAssemble(footer: item, sectionIndex: itemPath.section)
        case .cell:
            layout.setAndAssemble(item: item, sectionIndex: itemPath.section, itemIndex: itemPath.item)
        }
        storage[state] = layout
        let frameUpdateAction = CompensatingAction.frameUpdate(previousFrame: previousFrame, newFrame: item.frame)
        compensateOffsetIfNeeded(for: itemPath, kind: kind, action: frameUpdateAction)
    }

    func update(alignment: ChatItemAlignment, for itemPath: ItemPath, kind: ItemKind, at state: ModelState) {
        guard var item = item(for: itemPath, kind: kind, at: state) else {
            assertionFailure("Internal inconsistency")
            return
        }
        var layout = self.layout(at: state)
        cachedAttributesState = nil
        item.alignment = alignment

        switch kind {
        case .header:
            layout.setAndAssemble(header: item, sectionIndex: itemPath.section)
        case .footer:
            layout.setAndAssemble(footer: item, sectionIndex: itemPath.section)
        case .cell:
            layout.setAndAssemble(item: item, sectionIndex: itemPath.section, itemIndex: itemPath.item)
        }
        storage[state] = layout
    }

    func process(updateItems: [UICollectionViewUpdateItem]) {
        batchUpdateCompensatingOffset = 0
        proposedCompensatingOffset = 0

        var afterUpdateModel = layout(at: .beforeUpdate)
        resetCachedAttributeObjects()

        updateItems.forEach { updateItem in
            let updateAction = updateItem.updateAction
            let indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate
            let indexPathAfterUpdate = updateItem.indexPathAfterUpdate

            switch updateAction {
            case .none:
                break
            case .move:
                guard let indexPathBeforeUpdate = indexPathBeforeUpdate,
                    let indexPathAfterUpdate = indexPathAfterUpdate else {
                    assertionFailure("`indexPathBeforeUpdate` and `indexPathAfterUpdate` cannot be `nil` for a `.move` update action")
                    return
                }
                if indexPathBeforeUpdate.item == NSNotFound, indexPathAfterUpdate.item == NSNotFound {
                    let section = layout(at: .beforeUpdate).sections[indexPathBeforeUpdate.section]
                    movedSectionsIndexes.insert(indexPathBeforeUpdate.section)
                    afterUpdateModel.removeSection(by: section.id)
                    afterUpdateModel.insertSection(section, at: indexPathAfterUpdate.section)
                } else {
                    let itemId = itemIdentifier(for: indexPathBeforeUpdate.itemPath, kind: .cell, at: .beforeUpdate)!
                    let item = layout(at: .beforeUpdate).sections[indexPathBeforeUpdate.section].items[indexPathBeforeUpdate.item]
                    movedIndexes.insert(indexPathBeforeUpdate)
                    afterUpdateModel.removeItem(by: itemId)
                    afterUpdateModel.insertItem(item, at: indexPathAfterUpdate)
                }
            case .insert:
                guard let indexPath = indexPathAfterUpdate else {
                    assertionFailure("`indexPathAfterUpdate` cannot be `nil` for an `.insert` update action")
                    return
                }

                if indexPath.item == NSNotFound {
                    let items = (0..<layoutRepresentation.numberOfItems(in: indexPath.section)).map { index -> ItemModel in
                        let itemIndexPath = IndexPath(item: index, section: indexPath.section)
                        return ItemModel(with: layoutRepresentation.configuration(for: .cell, at: itemIndexPath.itemPath))
                    }
                    let header: ItemModel?
                    if layoutRepresentation.shouldPresentHeader(at: indexPath.section) == true {
                        let headerIndexPath = IndexPath(item: 0, section: indexPath.section)
                        header = ItemModel(with: layoutRepresentation.configuration(for: .header, at: headerIndexPath.itemPath))
                    } else {
                        header = nil
                    }
                    let footer: ItemModel?
                    if layoutRepresentation.shouldPresentFooter(at: indexPath.section) == true {
                        let footerIndexPath = IndexPath(item: 0, section: indexPath.section)
                        footer = ItemModel(with: layoutRepresentation.configuration(for: .footer, at: footerIndexPath.itemPath))
                    } else {
                        footer = nil
                    }
                    let section = SectionModel(header: header, footer: footer, items: items, collectionLayout: layoutRepresentation)
                    afterUpdateModel.insertSection(section, at: indexPath.section)
                    insertedSectionsIndexes.insert(indexPath.section)
                } else {
                    let item = ItemModel(with: layoutRepresentation.configuration(for: .cell, at: indexPath.itemPath))
                    insertedIndexes.insert(indexPath)
                    afterUpdateModel.insertItem(item, at: indexPath)
                }
            case .delete:
                guard let indexPath = indexPathBeforeUpdate else {
                    assertionFailure("`indexPathBeforeUpdate` cannot be `nil` for a `.delete` update action")
                    return
                }

                if indexPath.item == NSNotFound {
                    let section = layout(at: .beforeUpdate).sections[indexPath.section]
                    deletedSectionsIndexes.insert(indexPath.section)
                    afterUpdateModel.removeSection(by: section.id)
                } else {
                    let itemId = itemIdentifier(for: indexPath.itemPath, kind: .cell, at: .beforeUpdate)!
                    afterUpdateModel.removeItem(by: itemId)
                    deletedIndexes.insert(indexPath)
                }
            case .reload:
                guard let indexPath = indexPathBeforeUpdate else {
                    assertionFailure("`indexPathBeforeUpdate` cannot be `nil` for a `.reload` update action")
                    return
                }

                if indexPath.item == NSNotFound {
                    reloadedSectionsIndexes.insert(indexPath.section)
                    var section = layout(at: .beforeUpdate).sections[indexPath.section]

                    var header: ItemModel?
                    if layoutRepresentation.shouldPresentHeader(at: indexPath.section) == true {
                        let headerIndexPath = IndexPath(item: 0, section: indexPath.section)
                        header = section.header ?? ItemModel(with: layoutRepresentation.configuration(for: .header, at: headerIndexPath.itemPath))
                        header?.resetSize()
                    } else {
                        header = nil
                    }
                    section.set(header: header)

                    var footer: ItemModel?
                    if layoutRepresentation.shouldPresentFooter(at: indexPath.section) == true {
                        let footerIndexPath = IndexPath(item: 0, section: indexPath.section)
                        footer = section.footer ?? ItemModel(with: layoutRepresentation.configuration(for: .footer, at: footerIndexPath.itemPath))
                        footer?.resetSize()
                    } else {
                        footer = nil
                    }
                    section.set(footer: footer)

                    let oldItems = section.items
                    let items: [ItemModel] = (0..<layoutRepresentation.numberOfItems(in: indexPath.section)).map { index in
                        var newItem: ItemModel
                        if index < oldItems.count {
                            newItem = oldItems[index]
                        } else {
                            let itemIndexPath = IndexPath(item: index, section: indexPath.section)
                            newItem = ItemModel(with: layoutRepresentation.configuration(for: .cell, at: itemIndexPath.itemPath))
                        }
                        newItem.resetSize()
                        return newItem
                    }
                    section.set(items: items)
                    afterUpdateModel.removeSection(for: indexPath.section)
                    afterUpdateModel.insertSection(section, at: indexPath.section)
                } else {
                    guard var item = self.item(for: indexPath.itemPath, kind: .cell, at: .beforeUpdate) else {
                        assertionFailure("Internal inconsistency")
                        return
                    }
                    item.resetSize()

                    afterUpdateModel.replaceItem(item, at: indexPath)
                    reloadedIndexes.insert(indexPath)
                }
            default:
                assertionFailure("Unexpected action to process")
            }
        }

        afterUpdateModel = LayoutModel(sections: afterUpdateModel.sections.map { section -> SectionModel in
            var section = section
            section.assembleLayout()
            return section
        }, collectionLayout: layoutRepresentation)
        afterUpdateModel.assembleLayout()
        storage[.afterUpdate] = afterUpdateModel

        // Calculating potential content offset changes after the updates
        insertedSectionsIndexes.sorted(by: { $0 < $1 }).forEach {
            compensateOffsetOfSectionIfNeeded(for: $0, action: .insert)
        }
        reloadedSectionsIndexes.sorted(by: { $0 < $1 }).forEach {
            let oldSection = self.section(at: $0, at: .beforeUpdate)
            guard let newSectionIndex = self.sectionIndex(for: oldSection.id, at: .afterUpdate) else {
                assertionFailure("Internal inconsistency")
                return
            }
            let newSection = self.section(at: newSectionIndex, at: .afterUpdate)
            compensateOffsetOfSectionIfNeeded(for: $0, action: .frameUpdate(previousFrame: oldSection.frame, newFrame: newSection.frame))
        }
        deletedSectionsIndexes.sorted(by: { $0 < $1 }).forEach {
            compensateOffsetOfSectionIfNeeded(for: $0, action: .delete)
        }

        reloadedIndexes.sorted(by: { $0 < $1 }).forEach {
            guard let oldItem = self.item(for: $0.itemPath, kind: .cell, at: .beforeUpdate),
                let newItemIndexPath = self.itemPath(by: oldItem.id, at: .afterUpdate),
                let newItem = self.item(for: newItemIndexPath, kind: .cell, at: .afterUpdate) else {
                assertionFailure("Internal inconsistency")
                return
            }
            compensateOffsetIfNeeded(for: $0.itemPath, kind: .cell, action: .frameUpdate(previousFrame: oldItem.frame, newFrame: newItem.frame))
        }

        insertedIndexes.sorted(by: { $0 < $1 }).forEach {
            compensateOffsetIfNeeded(for: $0.itemPath, kind: .cell, action: .insert)
        }
        deletedIndexes.sorted(by: { $0 < $1 }).forEach {
            compensateOffsetIfNeeded(for: $0.itemPath, kind: .cell, action: .delete)
        }

        totalProposedCompensatingOffset = proposedCompensatingOffset
    }

    func commitUpdates() {
        insertedIndexes = []
        insertedSectionsIndexes = []

        reloadedIndexes = []
        reloadedSectionsIndexes = []

        movedIndexes = []
        movedSectionsIndexes = []

        deletedIndexes = []
        deletedSectionsIndexes = []

        storage[.beforeUpdate] = layout(at: .afterUpdate)
        storage[.afterUpdate] = nil

        totalProposedCompensatingOffset = 0

        cachedAttributeObjects[.beforeUpdate] = cachedAttributeObjects[.afterUpdate]
        resetCachedAttributeObjects(at: .afterUpdate)
    }

    func contentSize(for state: ModelState) -> CGSize {
        let contentHeight = self.contentHeight(at: state)
        guard contentHeight != 0 else {
            return .zero
        }
        // This is a workaround for `layoutAttributesForElementsInRect:` not getting invoked enough
        // times if `collectionViewContentSize.width` is not smaller than the width of the collection
        // view, minus horizontal insets. This results in visual defects when performing batch
        // updates. To work around this, we subtract 0.0001 from our content size width calculation;
        // this small decrease in `collectionViewContentSize.width` is enough to work around the
        // incorrect, internal collection view `CGRect` checks, without introducing any visual
        // differences for elements in the collection view.
        // See https://openradar.appspot.com/radar?id=5025850143539200 for more details.
        let contentSize = CGSize(width: layoutRepresentation.visibleBounds.size.width - 0.0001, height: contentHeight)
        return contentSize
    }

    func offsetByTotalCompensation(attributes: UICollectionViewLayoutAttributes?, for state: ModelState, backward: Bool = false) {
        guard layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates,
            state == .afterUpdate,
            let attributes = attributes else {
            return
        }
        if backward, isLayoutBiggerThanVisibleBounds(at: .afterUpdate) {
            attributes.frame = attributes.frame.offsetBy(dx: 0, dy: totalProposedCompensatingOffset * -1)
        } else if !backward, isLayoutBiggerThanVisibleBounds(at: .afterUpdate) {
            attributes.frame = attributes.frame.offsetBy(dx: 0, dy: totalProposedCompensatingOffset)
        }
    }

    func layout(at state: ModelState) -> LayoutModel {
        guard let layout = storage[state] else {
            assertionFailure("Internal inconsistency. Layout at \(state) is missing.")
            return LayoutModel(sections: [], collectionLayout: layoutRepresentation)
        }
        return layout
    }

    func isLayoutBiggerThanVisibleBounds(at state: ModelState, withFullCompensation: Bool = false) -> Bool {
        let visibleBoundsHeight = layoutRepresentation.visibleBounds.height + (withFullCompensation ? batchUpdateCompensatingOffset + proposedCompensatingOffset : 0)
        return contentHeight(at: state).rounded() > visibleBoundsHeight.rounded()
    }

    private func allAttributes(at state: ModelState, visibleRect: CGRect? = nil) -> [ChatLayoutAttributes] {
        let layout = self.layout(at: state)

        if let visibleRect = visibleRect {
            enum TraverseState {
                case notFound
                case found
                case done
            }

            var traverseState: TraverseState = .notFound

            func check(rect: CGRect) -> Bool {
                switch traverseState {
                case .notFound:
                    if visibleRect.intersects(rect) {
                        traverseState = .found
                        return true
                    } else {
                        return false
                    }
                case .found:
                    if visibleRect.intersects(rect) {
                        return true
                    } else {
                        if rect.minY > visibleRect.maxY + batchUpdateCompensatingOffset + proposedCompensatingOffset {
                            traverseState = .done
                        }
                        return false
                    }
                case .done:
                    return false
                }
            }

            var allRects = [(frame: CGRect, indexPath: ItemPath, kind: ItemKind)]()
            // I dont think there can be more then a 200 elements on the screen simultaneously
            allRects.reserveCapacity(200)
            let skipIndex = 100
            for sectionIndex in 0..<layout.sections.count {
                let section = layout.sections[sectionIndex]
                let sectionPath = ItemPath(item: 0, section: sectionIndex)
                if let headerFrame = itemFrame(for: sectionPath, kind: .header, at: state, isFinal: true),
                    check(rect: headerFrame) {
                    allRects.append((frame: headerFrame, indexPath: sectionPath, kind: .header))
                }
                guard traverseState != .done else {
                    break
                }

                var startingIndex = 0
                // Lets try to skip some calculations as visible rect most often is at the bottom of the layout
                if traverseState == .notFound {
                    var iterationIndex = skipIndex
                    while iterationIndex < section.items.count {
                        let itemPath = ItemPath(item: iterationIndex, section: sectionIndex)
                        let itemFrame = self.itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true)
                        if itemFrame == nil || itemFrame.map({ $0.maxY < visibleRect.minY ? true : false }) == true {
                            startingIndex = iterationIndex
                            iterationIndex += skipIndex
                            continue
                        } else {
                            break
                        }
                    }
                }
                if startingIndex < section.items.count {
                    for itemIndex in startingIndex..<section.items.count {
                        let itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                        if let itemFrame = self.itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true),
                            check(rect: itemFrame) {
                            if state == .beforeUpdate || isAnimatedBoundsChange {
                                allRects.append((frame: itemFrame, indexPath: itemPath, kind: .cell))
                            } else {
                                var itemWasVisibleBefore: Bool {
                                    guard let itemIdentifier = self.itemIdentifier(for: itemPath, kind: .cell, at: .afterUpdate),
                                        let initialIndexPath = self.itemPath(by: itemIdentifier, at: .beforeUpdate),
                                        let item = self.item(for: initialIndexPath, kind: .cell, at: .beforeUpdate),
                                        item.calculatedOnce == true,
                                        let itemFrame = self.itemFrame(for: initialIndexPath, kind: .cell, at: .beforeUpdate, isFinal: false),
                                        itemFrame.intersects(layoutRepresentation.visibleBounds.offsetBy(dx: 0, dy: -totalProposedCompensatingOffset)) else {
                                        return false
                                    }
                                    return true
                                }
                                var itemWillBeVisible: Bool {
                                    let offsetVisibleBounds = layoutRepresentation.visibleBounds.offsetBy(dx: 0, dy: proposedCompensatingOffset + batchUpdateCompensatingOffset)
                                    if insertedIndexes.contains(itemPath.indexPath),
                                        let itemFrame = self.itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true),
                                        itemFrame.intersects(offsetVisibleBounds) {
                                        return true
                                    }
                                    if let itemIdentifier = self.itemIdentifier(for: itemPath, kind: .cell, at: .afterUpdate),
                                        let initialIndexPath = self.itemPath(by: itemIdentifier, at: .beforeUpdate)?.indexPath,
                                        movedIndexes.contains(initialIndexPath) || reloadedIndexes.contains(initialIndexPath),
                                        let itemFrame = self.itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true),
                                        itemFrame.intersects(offsetVisibleBounds) {
                                        return true
                                    }
                                    return false
                                }
                                if itemWillBeVisible || itemWasVisibleBefore {
                                    allRects.append((frame: itemFrame, indexPath: itemPath, kind: .cell))
                                }
                            }
                        }
                        guard traverseState != .done else {
                            break
                        }
                    }
                }

                if let footerFrame = itemFrame(for: sectionPath, kind: .footer, at: state, isFinal: true),
                    check(rect: footerFrame) {
                    allRects.append((frame: footerFrame, indexPath: sectionPath, kind: .footer))
                }
            }

            return allRects.compactMap { frame, path, kind -> ChatLayoutAttributes? in
                return self.itemAttributes(for: path, kind: kind, predefinedFrame: frame, at: state)
            }
        } else {
            var attributes = [ChatLayoutAttributes]()
            attributes.reserveCapacity(layout.sections.count * 1000)
            layout.sections.enumerated().forEach { sectionIndex, section in
                let sectionPath = ItemPath(item: 0, section: sectionIndex)
                if let headerAttributes = self.itemAttributes(for: sectionPath, kind: .header, at: state) {
                    attributes.append(headerAttributes)
                }
                if let footerAttributes = self.itemAttributes(for: sectionPath, kind: .footer, at: state) {
                    attributes.append(footerAttributes)
                }
                section.items.enumerated().forEach { itemIndex, _ in
                    let itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                    if let itemAttributes = self.itemAttributes(for: itemPath, kind: .cell, at: state) {
                        attributes.append(itemAttributes)
                    }
                }
            }

            return attributes
        }
    }

    private func compensateOffsetIfNeeded(for itemPath: ItemPath, kind: ItemKind, action: CompensatingAction) {
        guard layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates else {
            return
        }
        let minY = (layoutRepresentation.visibleBounds.lowerPoint.y + batchUpdateCompensatingOffset + proposedCompensatingOffset).rounded()
        switch action {
        case .insert:
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate),
                let itemFrame = itemFrame(for: itemPath, kind: kind, at: .afterUpdate) else {
                return
            }
            if itemFrame.minY.rounded() - layoutRepresentation.settings.interItemSpacing <= minY {
                proposedCompensatingOffset += itemFrame.height + layoutRepresentation.settings.interItemSpacing
            }
        case let .frameUpdate(previousFrame, newFrame):
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate, withFullCompensation: true) else {
                return
            }
            if newFrame.minY.rounded() <= minY {
                batchUpdateCompensatingOffset += newFrame.height - previousFrame.height
            }
        case .delete:
            guard isLayoutBiggerThanVisibleBounds(at: .beforeUpdate),
                let deletedFrame = itemFrame(for: itemPath, kind: kind, at: .beforeUpdate) else {
                return
            }
            if deletedFrame.minY.rounded() <= minY {
                // Changing content offset for deleted items using `invalidateLayout(with:) causes UI glitches.
                // So we are using targetContentOffset(forProposedContentOffset:) which is going to be called after.
                proposedCompensatingOffset -= (deletedFrame.height + layoutRepresentation.settings.interItemSpacing)
            }
        }

    }

    private func compensateOffsetOfSectionIfNeeded(for sectionIndex: Int, action: CompensatingAction) {
        guard layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates else {
            return
        }
        let minY = (layoutRepresentation.visibleBounds.lowerPoint.y + batchUpdateCompensatingOffset + proposedCompensatingOffset).rounded()
        switch action {
        case .insert:
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate),
                sectionIndex < layout(at: .afterUpdate).sections.count else {
                return
            }
            let section = layout(at: .afterUpdate).sections[sectionIndex]

            if section.offsetY.rounded() - layoutRepresentation.settings.interSectionSpacing <= minY {
                proposedCompensatingOffset += section.height + layoutRepresentation.settings.interSectionSpacing
            }
        case let .frameUpdate(previousFrame, newFrame):
            guard sectionIndex < layout(at: .afterUpdate).sections.count,
                isLayoutBiggerThanVisibleBounds(at: .afterUpdate, withFullCompensation: true) else {
                return
            }
            if newFrame.minY.rounded() <= minY {
                batchUpdateCompensatingOffset += newFrame.height - previousFrame.height
            }
        case .delete:
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate),
                sectionIndex < layout(at: .afterUpdate).sections.count else {
                return
            }
            let section = layout(at: .beforeUpdate).sections[sectionIndex]
            if section.locationHeight.rounded() <= minY {
                // Changing content offset for deleted items using `invalidateLayout(with:) causes UI glitches.
                // So we are using targetContentOffset(forProposedContentOffset:) which is going to be called after.
                proposedCompensatingOffset -= (section.height + layoutRepresentation.settings.interSectionSpacing)
            }
        }

    }

    private func offsetByCompensation(frame: CGRect,
                                      at itemPath: ItemPath,
                                      for state: ModelState,
                                      backward: Bool = false) -> CGRect {
        guard layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates,
            state == .afterUpdate,
            isLayoutBiggerThanVisibleBounds(at: .afterUpdate) else {
            return frame
        }
        return frame.offsetBy(dx: 0, dy: proposedCompensatingOffset * (backward ? -1 : 1))
    }

}
