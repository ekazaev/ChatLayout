//
// ChatLayout
// StateController.swift
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

/// This protocol exists only to serve an ability to unit test `StateController`.
protocol ChatLayoutRepresentation: AnyObject {

    var settings: ChatLayoutSettings { get }

    var viewSize: CGSize { get }

    var visibleBounds: CGRect { get }

    var layoutFrame: CGRect { get }

    var adjustedContentInset: UIEdgeInsets { get }

    var keepContentOffsetAtBottomOnBatchUpdates: Bool { get }

    var processOnlyVisibleItemsOnAnimatedBatchUpdates: Bool { get }

    func numberOfItems(in section: Int) -> Int

    func configuration(for element: ItemKind, at indexPath: IndexPath) -> ItemModel.Configuration

    func shouldPresentHeader(at sectionIndex: Int) -> Bool

    func shouldPresentFooter(at sectionIndex: Int) -> Bool

    func interSectionSpacing(at sectionIndex: Int) -> CGFloat
}

final class StateController<Layout: ChatLayoutRepresentation> {

    // Helps to reduce the amount of looses in bridging calls to objc `UICollectionView` getter methods.
    struct AdditionalLayoutAttributes {

        fileprivate let additionalInsets: UIEdgeInsets

        fileprivate let viewSize: CGSize

        fileprivate let adjustedContentInsets: UIEdgeInsets

        fileprivate let visibleBounds: CGRect

        fileprivate let layoutFrame: CGRect

        fileprivate init(_ layoutRepresentation: ChatLayoutRepresentation) {
            viewSize = layoutRepresentation.viewSize
            adjustedContentInsets = layoutRepresentation.adjustedContentInset
            visibleBounds = layoutRepresentation.visibleBounds
            layoutFrame = layoutRepresentation.layoutFrame
            additionalInsets = layoutRepresentation.settings.additionalInsets
        }
    }

    private enum CompensatingAction {
        case insert(spacing: CGFloat)
        case delete(spacing: CGFloat)
        case frameUpdate(previousFrame: CGRect, newFrame: CGRect, previousSpacing: CGFloat, newSpacing: CGFloat)
    }

    private enum TraverseState {
        case notFound
        case found
        case done
    }

    // This thing exists here as `UICollectionView` calls `targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint)`
    // only once at the beginning of the animated updates. But we must compensate the other changes that happened during the update.
    var batchUpdateCompensatingOffset: CGFloat = 0

    var proposedCompensatingOffset: CGFloat = 0

    var totalProposedCompensatingOffset: CGFloat = 0

    var isAnimatedBoundsChange = false

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

    private var layoutBeforeUpdate: LayoutModel<Layout>

    private var layoutAfterUpdate: LayoutModel<Layout>?

    private unowned var layoutRepresentation: Layout

    init(layoutRepresentation: Layout) {
        self.layoutRepresentation = layoutRepresentation
        layoutBeforeUpdate = LayoutModel(sections: [], collectionLayout: self.layoutRepresentation)
        resetCachedAttributeObjects()
    }

    func set(_ sections: ContiguousArray<SectionModel<Layout>>,
             at state: ModelState) {
        let layoutModel = LayoutModel(sections: sections, collectionLayout: layoutRepresentation)
        layoutModel.assembleLayout()
        switch state {
        case .beforeUpdate:
            layoutBeforeUpdate = layoutModel
        case .afterUpdate:
            layoutAfterUpdate = layoutModel
        }
    }

    func contentHeight(at state: ModelState) -> CGFloat {
        let locationHeight: CGFloat?
        switch state {
        case .beforeUpdate:
            locationHeight = layoutBeforeUpdate.sections.withUnsafeBufferPointer { $0.last?.locationHeight }
        case .afterUpdate:
            locationHeight = layoutAfterUpdate?.sections.withUnsafeBufferPointer { $0.last?.locationHeight }
        }

        guard let locationHeight else {
            return 0
        }
        return locationHeight + layoutRepresentation.settings.additionalInsets.bottom
    }

    func layoutAttributesForElements(in rect: CGRect,
                                     state: ModelState,
                                     ignoreCache: Bool = false) -> [ChatLayoutAttributes] {
        let predicate: (ChatLayoutAttributes) -> ComparisonResult = { attributes in
            if attributes.frame.intersects(rect) {
                return .orderedSame
            } else if attributes.frame.minY >= rect.maxY {
                return .orderedDescending
            } else if attributes.frame.maxY <= rect.minY {
                return .orderedAscending
            }
            return .orderedSame
        }

        if !ignoreCache,
           let cachedAttributesState,
           cachedAttributesState.rect.contains(rect) {
            return cachedAttributesState.attributes.withUnsafeBufferPointer { $0.binarySearchRange(predicate: predicate) }
        } else {
            let totalRect: CGRect
            switch state {
            case .beforeUpdate:
                totalRect = rect.inset(by: UIEdgeInsets(top: -rect.height / 2, left: -rect.width / 2, bottom: -rect.height / 2, right: -rect.width / 2))
            case .afterUpdate:
                totalRect = rect
            }
            let attributes = allAttributes(at: state, visibleRect: totalRect)
            if !ignoreCache {
                cachedAttributesState = (rect: totalRect, attributes: attributes)
            }
            let visibleAttributes = rect != totalRect ? attributes.withUnsafeBufferPointer { $0.binarySearchRange(predicate: predicate) } : attributes
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
                        at state: ModelState,
                        additionalAttributes: AdditionalLayoutAttributes? = nil) -> ChatLayoutAttributes? {
        let additionalAttributes = additionalAttributes ?? AdditionalLayoutAttributes(layoutRepresentation)

        let attributes: ChatLayoutAttributes
        let itemIndexPath = itemPath.indexPath
        let layout = layout(at: state)

        switch kind {
        case .header:
            guard itemPath.section < layout.sections.count,
                  itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let headerFrame = predefinedFrame ?? itemFrame(for: itemPath,
                                                                 kind: kind,
                                                                 at: state,
                                                                 isFinal: true,
                                                                 additionalAttributes: additionalAttributes),
                let item = item(for: itemPath, kind: kind, at: state) else {
                return nil
            }
            if let cachedAttributes = cachedAttributeObjects[state]?[.header]?[itemPath] {
                attributes = cachedAttributes
            } else {
                attributes = ChatLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                                  with: itemIndexPath)
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
            guard itemPath.section < layout.sections.count,
                  itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let footerFrame = predefinedFrame ?? itemFrame(for: itemPath,
                                                                 kind: kind,
                                                                 at: state,
                                                                 isFinal: true,
                                                                 additionalAttributes: additionalAttributes),
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
            guard itemPath.section < layout.sections.count,
                  itemPath.item < layout.sections[itemPath.section].items.count else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let itemFrame = predefinedFrame ?? itemFrame(for: itemPath,
                                                               kind: .cell,
                                                               at: state,
                                                               isFinal: true,
                                                               additionalAttributes: additionalAttributes),
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
        attributes.viewSize = additionalAttributes.viewSize
        attributes.adjustedContentInsets = additionalAttributes.adjustedContentInsets
        attributes.visibleBoundsSize = additionalAttributes.visibleBounds.size
        attributes.layoutFrame = additionalAttributes.layoutFrame
        attributes.additionalInsets = additionalAttributes.additionalInsets
        return attributes
    }

    func itemFrame(for itemPath: ItemPath,
                   kind: ItemKind,
                   at state: ModelState,
                   isFinal: Bool = false,
                   additionalAttributes: AdditionalLayoutAttributes? = nil) -> CGRect? {
        let additionalAttributes = additionalAttributes ?? AdditionalLayoutAttributes(layoutRepresentation)
        let layout = layout(at: state)
        guard itemPath.section < layout.sections.count else {
            return nil
        }
        guard let item = item(for: itemPath, kind: kind, at: state) else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }

        let section = layout.sections[itemPath.section]
        var itemFrame = item.frame
        let dx: CGFloat
        let visibleBounds = additionalAttributes.visibleBounds
        let additionalInsets = additionalAttributes.additionalInsets

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
            itemFrame.size.width = additionalAttributes.layoutFrame.size.width
        }

        itemFrame.offsettingBy(dx: dx, dy: section.offsetY)
        if isFinal {
            offsetByCompensation(frame: &itemFrame, at: itemPath, for: state, backward: true)
        }
        return itemFrame
    }

    func itemPath(by itemId: UUID, kind: ItemKind, at state: ModelState) -> ItemPath? {
        layout(at: state).itemPath(by: itemId, kind: kind)
    }

    func sectionIdentifier(for index: Int, at state: ModelState) -> UUID? {
        let layout = layout(at: state)
        guard index < layout.sections.count else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }
        return layout.sections[index].id
    }

    func sectionIndex(for sectionIdentifier: UUID, at state: ModelState) -> Int? {
        guard let sectionIndex = layout(at: state).sectionIndex(by: sectionIdentifier) else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }
        return sectionIndex
    }

    func section(at index: Int, at state: ModelState) -> SectionModel<Layout> {
        #if DEBUG
        guard index < layout(at: state).sections.count else {
            preconditionFailure("Section index \(index) is bigger than the amount of sections \(layout(at: state).sections.count).")
        }
        #endif
        return layout(at: state).sections[index]
    }

    func itemIdentifier(for itemPath: ItemPath, kind: ItemKind, at state: ModelState) -> UUID? {
        let layout = layout(at: state)
        guard itemPath.section < layout.sections.count else {
            // This occurs when getting layout attributes for initial / final animations
            return nil
        }
        let sectionModel = layout.sections[itemPath.section]
        switch kind {
        case .cell:
            guard itemPath.item < layout.sections[itemPath.section].items.count else {
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
        layout(at: state).sections.count
    }

    func numberOfItems(in sectionIndex: Int, at state: ModelState) -> Int {
        layout(at: state).sections[sectionIndex].items.count
    }

    func item(for itemPath: ItemPath, kind: ItemKind, at state: ModelState) -> ItemModel? {
        let layout = layout(at: state)
        switch kind {
        case .header:
            guard itemPath.section < layout.sections.count,
                  itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let header = layout.sections[itemPath.section].header else {
                return nil
            }
            return header
        case .footer:
            guard itemPath.section < layout.sections.count,
                  itemPath.item == 0 else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            guard let footer = layout.sections[itemPath.section].footer else {
                return nil
            }
            return footer
        case .cell:
            guard itemPath.section < layout.sections.count,
                  itemPath.item < layout.sections[itemPath.section].items.count else {
                // This occurs when getting layout attributes for initial / final animations
                return nil
            }
            return layout.sections[itemPath.section].items[itemPath.item]
        }
    }

    func update(preferredSize: CGSize,
                alignment: ChatItemAlignment,
                interItemSpacing: CGFloat,
                for itemPath: ItemPath,
                kind: ItemKind,
                at state: ModelState) {
        guard var item = item(for: itemPath, kind: kind, at: state) else {
            assertionFailure("Item at index path (\(itemPath.section) - \(itemPath.item)) does not exist.")
            return
        }

        let previousFrame = item.frame
        let previousInterItemSpacing = item.interItemSpacing
        cachedAttributesState = nil
        item.alignment = alignment
        item.calculatedSize = preferredSize
        item.calculatedOnce = true

        switch state {
        case .beforeUpdate:
            switch kind {
            case .header:
                layoutBeforeUpdate.setAndAssemble(header: item, sectionIndex: itemPath.section)
            case .footer:
                layoutBeforeUpdate.setAndAssemble(footer: item, sectionIndex: itemPath.section)
            case .cell:
                layoutBeforeUpdate.setAndAssemble(item: item,
                                                  sectionIndex: itemPath.section,
                                                  itemIndex: itemPath.item)
            }
        case .afterUpdate:
            switch kind {
            case .header:
                layoutAfterUpdate?.setAndAssemble(header: item, sectionIndex: itemPath.section)
            case .footer:
                layoutAfterUpdate?.setAndAssemble(footer: item, sectionIndex: itemPath.section)
            case .cell:
                layoutAfterUpdate?.setAndAssemble(item: item,
                                                  sectionIndex: itemPath.section,
                                                  itemIndex: itemPath.item)
            }
        }

        let frameUpdateAction = CompensatingAction.frameUpdate(previousFrame: previousFrame,
                                                               newFrame: item.frame,
                                                               previousSpacing: previousInterItemSpacing,
                                                               newSpacing: interItemSpacing)
        compensateOffsetIfNeeded(for: itemPath, kind: kind, action: frameUpdateAction)
    }

    func process(changeItems: [ChangeItem]) {
        func applyConfiguration(_ configuration: ItemModel.Configuration, to item: inout ItemModel) {
            item.alignment = configuration.alignment
            if let calculatedSize = configuration.calculatedSize {
                item.calculatedSize = calculatedSize
                item.calculatedOnce = true
            } else {
                item.resetSize()
            }
        }

        batchUpdateCompensatingOffset = 0
        proposedCompensatingOffset = 0
        let changeItems = changeItems.sorted()

        var afterUpdateModel = LayoutModel(sections: layoutBeforeUpdate.sections,
                                           collectionLayout: layoutRepresentation)
        resetCachedAttributeObjects()

        changeItems.forEach { updateItem in
            switch updateItem {
            case let .sectionInsert(sectionIndex: sectionIndex):
                let items = (0..<layoutRepresentation.numberOfItems(in: sectionIndex)).map { index -> ItemModel in
                    let itemIndexPath = IndexPath(item: index, section: sectionIndex)
                    return ItemModel(with: layoutRepresentation.configuration(for: .cell, at: itemIndexPath))
                }
                let header: ItemModel?
                if layoutRepresentation.shouldPresentHeader(at: sectionIndex) == true {
                    let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
                    header = ItemModel(with: layoutRepresentation.configuration(for: .header, at: headerIndexPath))
                } else {
                    header = nil
                }
                let footer: ItemModel?
                if layoutRepresentation.shouldPresentFooter(at: sectionIndex) == true {
                    let footerIndexPath = IndexPath(item: 0, section: sectionIndex)
                    footer = ItemModel(with: layoutRepresentation.configuration(for: .footer, at: footerIndexPath))
                } else {
                    footer = nil
                }
                let section = SectionModel(interSectionSpacing: layoutRepresentation.interSectionSpacing(at: sectionIndex),
                                           header: header,
                                           footer: footer,
                                           items: ContiguousArray(items),
                                           collectionLayout: layoutRepresentation)
                afterUpdateModel.insertSection(section, at: sectionIndex)
                insertedSectionsIndexes.insert(sectionIndex)
            case let .itemInsert(itemIndexPath: indexPath):
                let item = ItemModel(with: layoutRepresentation.configuration(for: .cell, at: indexPath))
                insertedIndexes.insert(indexPath)
                afterUpdateModel.insertItem(item, at: indexPath)
            case let .sectionDelete(sectionIndex: sectionIndex):
                let section = layoutBeforeUpdate.sections[sectionIndex]
                deletedSectionsIndexes.insert(sectionIndex)
                afterUpdateModel.removeSection(by: section.id)
            case let .itemDelete(itemIndexPath: indexPath):
                let itemId = itemIdentifier(for: indexPath.itemPath, kind: .cell, at: .beforeUpdate)!
                afterUpdateModel.removeItem(by: itemId)
                deletedIndexes.insert(indexPath)
            case let .sectionReload(sectionIndex: sectionIndex):
                reloadedSectionsIndexes.insert(sectionIndex)
                var section = layoutBeforeUpdate.sections[sectionIndex]

                var header: ItemModel?
                if layoutRepresentation.shouldPresentHeader(at: sectionIndex) == true {
                    let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
                    var newHeader = section.header ?? ItemModel(with: layoutRepresentation.configuration(for: .header,
                                                                                                         at: headerIndexPath))
                    let configuration = layoutRepresentation.configuration(for: .header, at: headerIndexPath)
                    applyConfiguration(configuration, to: &newHeader)
                    header = newHeader
                } else {
                    header = nil
                }
                section.set(header: header)

                var footer: ItemModel?
                if layoutRepresentation.shouldPresentFooter(at: sectionIndex) == true {
                    let footerIndexPath = IndexPath(item: 0, section: sectionIndex)
                    var newFooter = section.footer ?? ItemModel(with: layoutRepresentation.configuration(for: .footer,
                                                                                                         at: footerIndexPath))
                    let configuration = layoutRepresentation.configuration(for: .footer, at: footerIndexPath)
                    applyConfiguration(configuration, to: &newFooter)
                    footer = newFooter
                } else {
                    footer = nil
                }
                section.set(footer: footer)

                let oldItems = section.items
                let items: [ItemModel] = (0..<layoutRepresentation.numberOfItems(in: sectionIndex)).map { index in
                    var newItem: ItemModel
                    let itemIndexPath = IndexPath(item: index, section: sectionIndex)
                    if index < oldItems.count {
                        newItem = oldItems[index]
                        let configuration = layoutRepresentation.configuration(for: .cell, at: itemIndexPath)
                        applyConfiguration(configuration, to: &newItem)
                    } else {
                        newItem = ItemModel(with: layoutRepresentation.configuration(for: .cell, at: itemIndexPath))
                    }
                    return newItem
                }
                section.set(items: ContiguousArray(items))
                afterUpdateModel.removeSection(for: sectionIndex)
                afterUpdateModel.insertSection(section, at: sectionIndex)
            case let .itemReload(itemIndexPath: indexPath):
                guard var item = item(for: indexPath.itemPath, kind: .cell, at: .beforeUpdate) else {
                    assertionFailure("Item at index path (\(indexPath.section) - \(indexPath.item)) does not exist.")
                    return
                }
                let configuration = layoutRepresentation.configuration(for: .cell, at: indexPath)
                applyConfiguration(configuration, to: &item)
                afterUpdateModel.replaceItem(item, at: indexPath)
                reloadedIndexes.insert(indexPath)
            case let .sectionMove(initialSectionIndex: initialSectionIndex, finalSectionIndex: finalSectionIndex):
                let section = layoutBeforeUpdate.sections[initialSectionIndex]
                movedSectionsIndexes.insert(finalSectionIndex)
                afterUpdateModel.removeSection(by: section.id)
                afterUpdateModel.insertSection(section, at: finalSectionIndex)
            case let .itemMove(initialItemIndexPath: initialItemIndexPath, finalItemIndexPath: finalItemIndexPath):
                let itemId = itemIdentifier(for: initialItemIndexPath.itemPath, kind: .cell, at: .beforeUpdate)!
                let item = layoutBeforeUpdate.sections[initialItemIndexPath.section].items[initialItemIndexPath.item]
                movedIndexes.insert(initialItemIndexPath)
                afterUpdateModel.removeItem(by: itemId)
                afterUpdateModel.insertItem(item, at: finalItemIndexPath)
            }
        }

        var afterUpdateModelSections = afterUpdateModel.sections
        afterUpdateModelSections.withUnsafeMutableBufferPointer { directlyMutableSections in
            for index in 0..<directlyMutableSections.count {
                directlyMutableSections[index].assembleLayout()
            }
        }
        afterUpdateModel = LayoutModel(sections: afterUpdateModelSections, collectionLayout: layoutRepresentation)
        afterUpdateModel.assembleLayout()

        layoutAfterUpdate = afterUpdateModel

        let visibleBounds = layoutRepresentation.visibleBounds

        // Calculating potential content offset changes after the updates
        insertedSectionsIndexes.sorted(by: { $0 < $1 }).forEach {
            let section = section(at: $0, at: .afterUpdate)
            compensateOffsetOfSectionIfNeeded(for: $0,
                                              action: .insert(spacing: section.interSectionSpacing),
                                              visibleBounds: visibleBounds)
        }
        reloadedSectionsIndexes.sorted(by: { $0 < $1 }).forEach {
            let oldSection = section(at: $0, at: .beforeUpdate)
            guard let newSectionIndex = sectionIndex(for: oldSection.id, at: .afterUpdate) else {
                assertionFailure("Section with identifier \(oldSection.id) does not exist.")
                return
            }
            let newSection = section(at: newSectionIndex, at: .afterUpdate)
            compensateOffsetOfSectionIfNeeded(for: $0,
                                              action: .frameUpdate(previousFrame: oldSection.frame,
                                                                   newFrame: newSection.frame,
                                                                   previousSpacing: oldSection.interSectionSpacing,
                                                                   newSpacing: newSection.interSectionSpacing),
                                              visibleBounds: visibleBounds)
        }
        deletedSectionsIndexes.sorted(by: { $0 < $1 }).forEach {
            let section = section(at: $0, at: .beforeUpdate)
            compensateOffsetOfSectionIfNeeded(for: $0,
                                              action: .delete(spacing: section.interSectionSpacing),
                                              visibleBounds: visibleBounds)
        }

        reloadedIndexes.sorted(by: { $0 < $1 }).forEach {
            let newItemPath = $0.itemPath
            guard let oldItem = item(for: newItemPath, kind: .cell, at: .beforeUpdate),
                  let newItemIndexPath = itemPath(by: oldItem.id, kind: .cell, at: .afterUpdate),
                  let newItem = item(for: newItemIndexPath, kind: .cell, at: .afterUpdate) else {
                assertionFailure("Internal inconsistency.")
                return
            }
            compensateOffsetIfNeeded(for: newItemPath,
                                     kind: .cell,
                                     action: .frameUpdate(previousFrame: oldItem.frame,
                                                          newFrame: newItem.frame,
                                                          previousSpacing: oldItem.interItemSpacing,
                                                          newSpacing: newItem.interItemSpacing),
                                     visibleBounds: visibleBounds)
        }
        insertedIndexes.sorted(by: { $0 < $1 }).forEach {
            let itemPath = $0.itemPath
            guard let item = item(for: itemPath, kind: .cell, at: .afterUpdate) else {
                assertionFailure("Internal inconsistency.")
                return
            }
            compensateOffsetIfNeeded(for: itemPath,
                                     kind: .cell,
                                     action: .insert(spacing: item.interItemSpacing),
                                     visibleBounds: visibleBounds)
        }
        deletedIndexes.sorted(by: { $0 < $1 }).forEach {
            let itemPath = $0.itemPath
            guard let item = item(for: itemPath, kind: .cell, at: .beforeUpdate) else {
                assertionFailure("Internal inconsistency.")
                return
            }
            compensateOffsetIfNeeded(for: itemPath,
                                     kind: .cell,
                                     action: .delete(spacing: item.interItemSpacing),
                                     visibleBounds: visibleBounds)
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

        layoutBeforeUpdate = layout(at: .afterUpdate)
        layoutAfterUpdate = nil

        totalProposedCompensatingOffset = 0

        cachedAttributeObjects[.beforeUpdate] = cachedAttributeObjects[.afterUpdate]
        resetCachedAttributeObjects(at: .afterUpdate)
    }

    func contentSize(for state: ModelState) -> CGSize {
        let contentHeight = contentHeight(at: state)
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
              let attributes else {
            return
        }
        if backward, isLayoutBiggerThanVisibleBounds(at: .afterUpdate) {
            attributes.frame.offsettingBy(dx: 0, dy: totalProposedCompensatingOffset * -1)
        } else if !backward, isLayoutBiggerThanVisibleBounds(at: .afterUpdate) {
            attributes.frame.offsettingBy(dx: 0, dy: totalProposedCompensatingOffset)
        }
    }

    func layout(at state: ModelState) -> LayoutModel<Layout> {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate
        case .afterUpdate:
            guard let layoutAfterUpdate else {
                assertionFailure("Internal inconsistency. Layout at \(state) is missing.")
                return LayoutModel(sections: [], collectionLayout: layoutRepresentation)
            }
            return layoutAfterUpdate
        }
    }

    func isLayoutBiggerThanVisibleBounds(at state: ModelState,
                                         withFullCompensation: Bool = false,
                                         visibleBounds: CGRect? = nil) -> Bool {
        let visibleBounds = visibleBounds ?? layoutRepresentation.visibleBounds
        let visibleBoundsHeight = visibleBounds.height + (withFullCompensation ? batchUpdateCompensatingOffset + proposedCompensatingOffset : 0)
        return contentHeight(at: state).rounded() > visibleBoundsHeight.rounded()
    }

    private func allAttributes(at state: ModelState, visibleRect: CGRect? = nil) -> [ChatLayoutAttributes] {
        let layout = layout(at: state)
        let additionalAttributes = AdditionalLayoutAttributes(layoutRepresentation)

        if let visibleRect {
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
                        if rect.minY >= visibleRect.maxY + batchUpdateCompensatingOffset + proposedCompensatingOffset {
                            traverseState = .done
                        }
                        return false
                    }
                case .done:
                    return false
                }
            }

            var allRects = ContiguousArray<(frame: CGRect, indexPath: ItemPath, kind: ItemKind)>()
            // I dont think there can be more then a 200 elements on the screen simultaneously
            allRects.reserveCapacity(200)

            let comparisonResults = [ComparisonResult.orderedSame, .orderedDescending]

            for sectionIndex in 0..<layout.sections.count {
                let section = layout.sections[sectionIndex]
                let sectionPath = ItemPath(item: 0, section: sectionIndex)
                if let headerFrame = itemFrame(for: sectionPath,
                                               kind: .header,
                                               at: state,
                                               isFinal: true,
                                               additionalAttributes: additionalAttributes),
                    check(rect: headerFrame) {
                    allRects.append((frame: headerFrame, indexPath: sectionPath, kind: .header))
                }
                guard traverseState != .done else {
                    break
                }

                var startingIndex = 0
                // If header is not visible
                if traverseState == .notFound, !section.items.isEmpty {
                    func predicate(itemIndex: Int) -> ComparisonResult {
                        let itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                        guard let itemFrame = itemFrame(for: itemPath,
                                                        kind: .cell,
                                                        at: state,
                                                        isFinal: true,
                                                        additionalAttributes: additionalAttributes) else {
                            return .orderedDescending
                        }
                        if itemFrame.intersects(visibleRect) {
                            return .orderedSame
                        } else if itemFrame.minY >= visibleRect.maxY {
                            return .orderedDescending
                        } else if itemFrame.maxX <= visibleRect.minY {
                            return .orderedAscending
                        }
                        return .orderedSame
                    }

                    // Find if any of the items of the section is visible

                    if comparisonResults.contains(predicate(itemIndex: section.items.count - 1)),
                       let firstMatchingIndex = ContiguousArray(0...section.items.count - 1).withUnsafeBufferPointer({ $0.binarySearch(predicate: predicate) }) {
                        // Find first item that is visible
                        startingIndex = firstMatchingIndex
                        for itemIndex in (0..<firstMatchingIndex).reversed() {
                            let itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                            guard let itemFrame = itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true,
                                                            additionalAttributes: additionalAttributes) else {
                                continue
                            }
                            guard itemFrame.maxY >= visibleRect.minY else {
                                break
                            }
                            startingIndex = itemIndex
                        }
                    } else {
                        // Otherwise we can safely skip all the items in the section and go to footer.
                        startingIndex = section.items.count
                    }
                }

                if startingIndex < section.items.count {
                    for itemIndex in startingIndex..<section.items.count {
                        let itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                        if let itemFrame = itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true,
                                                     additionalAttributes: additionalAttributes),
                            check(rect: itemFrame) {
                            if state == .beforeUpdate || isAnimatedBoundsChange || !layoutRepresentation.processOnlyVisibleItemsOnAnimatedBatchUpdates {
                                allRects.append((frame: itemFrame, indexPath: itemPath, kind: .cell))
                            } else {
                                var itemWasVisibleBefore: Bool {
                                    guard let itemIdentifier = itemIdentifier(for: itemPath, kind: .cell, at: .afterUpdate),
                                          let initialIndexPath = self.itemPath(by: itemIdentifier, kind: .cell, at: .beforeUpdate),
                                          let item = item(for: initialIndexPath, kind: .cell, at: .beforeUpdate),
                                          item.calculatedOnce == true,
                                          let itemFrame = self.itemFrame(for: initialIndexPath, kind: .cell, at: .beforeUpdate, isFinal: false, additionalAttributes: additionalAttributes),
                                          itemFrame.intersects(additionalAttributes.visibleBounds.offsetBy(dx: 0, dy: -totalProposedCompensatingOffset)) else {
                                        return false
                                    }
                                    return true
                                }
                                var itemWillBeVisible: Bool {
                                    let offsetVisibleBounds = additionalAttributes.visibleBounds.offsetBy(dx: 0, dy: proposedCompensatingOffset + batchUpdateCompensatingOffset)
                                    if insertedIndexes.contains(itemPath.indexPath),
                                       let itemFrame = self.itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true, additionalAttributes: additionalAttributes),
                                       itemFrame.intersects(offsetVisibleBounds) {
                                        return true
                                    }
                                    if let itemIdentifier = itemIdentifier(for: itemPath, kind: .cell, at: .afterUpdate),
                                       let initialIndexPath = self.itemPath(by: itemIdentifier, kind: .cell, at: .beforeUpdate)?.indexPath,
                                       movedIndexes.contains(initialIndexPath) || reloadedIndexes.contains(initialIndexPath),
                                       let itemFrame = self.itemFrame(for: itemPath, kind: .cell, at: state, isFinal: true, additionalAttributes: additionalAttributes),
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

                if let footerFrame = itemFrame(for: sectionPath, kind: .footer, at: state, isFinal: true, additionalAttributes: additionalAttributes),
                   check(rect: footerFrame) {
                    allRects.append((frame: footerFrame, indexPath: sectionPath, kind: .footer))
                }
            }

            return allRects.compactMap { frame, path, kind -> ChatLayoutAttributes? in
                itemAttributes(for: path, kind: kind, predefinedFrame: frame, at: state, additionalAttributes: additionalAttributes)
            }
        } else {
            // Debug purposes only.
            var attributes = [ChatLayoutAttributes]()
            attributes.reserveCapacity(layout.sections.reduce(into: 0) { $0 += $1.items.count })
            layout.sections.enumerated().forEach { sectionIndex, section in
                let sectionPath = ItemPath(item: 0, section: sectionIndex)
                if let headerAttributes = itemAttributes(for: sectionPath, kind: .header, at: state, additionalAttributes: additionalAttributes) {
                    attributes.append(headerAttributes)
                }
                if let footerAttributes = itemAttributes(for: sectionPath, kind: .footer, at: state, additionalAttributes: additionalAttributes) {
                    attributes.append(footerAttributes)
                }
                section.items.enumerated().forEach { itemIndex, _ in
                    let itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                    if let itemAttributes = itemAttributes(for: itemPath, kind: .cell, at: state, additionalAttributes: additionalAttributes) {
                        attributes.append(itemAttributes)
                    }
                }
            }

            return attributes
        }
    }

    private func compensateOffsetIfNeeded(for itemPath: ItemPath,
                                          kind: ItemKind,
                                          action: CompensatingAction,
                                          visibleBounds: CGRect? = nil) {
        guard layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates else {
            return
        }

        let visibleBounds = visibleBounds ?? layoutRepresentation.visibleBounds
        let minY = (visibleBounds.lowerPoint.y + batchUpdateCompensatingOffset + proposedCompensatingOffset).rounded()

        switch action {
        case let .insert(interItemSpacing):
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate, visibleBounds: visibleBounds),
                  let itemFrame = itemFrame(for: itemPath, kind: kind, at: .afterUpdate) else {
                return
            }
            if itemFrame.minY.rounded() - interItemSpacing <= minY {
                proposedCompensatingOffset += itemFrame.height + interItemSpacing
            }
        case let .frameUpdate(previousFrame, newFrame, oldInterItemSpacing, newInterItemSpacing):
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate, withFullCompensation: true, visibleBounds: visibleBounds) else {
                return
            }
            if newFrame.minY.rounded() <= minY {
                batchUpdateCompensatingOffset += newFrame.height - previousFrame.height + newInterItemSpacing - oldInterItemSpacing
            }
        case let .delete(interItemSpacing):
            guard isLayoutBiggerThanVisibleBounds(at: .beforeUpdate, visibleBounds: visibleBounds),
                  let deletedFrame = itemFrame(for: itemPath, kind: kind, at: .beforeUpdate) else {
                return
            }
            if deletedFrame.minY.rounded() <= minY {
                // Changing content offset for deleted items using `invalidateLayout(with:) causes UI glitches.
                // So we are using targetContentOffset(forProposedContentOffset:) which is going to be called after.
                proposedCompensatingOffset -= (deletedFrame.height + interItemSpacing)
            }
        }
    }

    private func compensateOffsetOfSectionIfNeeded(for sectionIndex: Int,
                                                   action: CompensatingAction,
                                                   visibleBounds: CGRect? = nil) {
        guard layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates else {
            return
        }

        let visibleBounds = visibleBounds ?? layoutRepresentation.visibleBounds
        let minY = (visibleBounds.lowerPoint.y + batchUpdateCompensatingOffset + proposedCompensatingOffset).rounded()

        switch action {
        case let .insert(interSectionSpacing):
            let sectionsAfterUpdate = layout(at: .afterUpdate).sections
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate, visibleBounds: visibleBounds),
                  sectionIndex < sectionsAfterUpdate.count else {
                return
            }
            let section = sectionsAfterUpdate[sectionIndex]

            if section.offsetY.rounded() - interSectionSpacing <= minY {
                proposedCompensatingOffset += section.height + interSectionSpacing
            }
        case let .frameUpdate(previousFrame, newFrame, oldInterSectionSpacing, newInterSectionSpacing):
            guard sectionIndex < layout(at: .afterUpdate).sections.count,
                  isLayoutBiggerThanVisibleBounds(at: .afterUpdate, withFullCompensation: true, visibleBounds: visibleBounds) else {
                return
            }
            if newFrame.minY.rounded() <= minY {
                batchUpdateCompensatingOffset += newFrame.height - previousFrame.height + newInterSectionSpacing - oldInterSectionSpacing
            }
        case let .delete(interSectionSpacing):
            guard isLayoutBiggerThanVisibleBounds(at: .afterUpdate, visibleBounds: visibleBounds),
                  sectionIndex < layout(at: .afterUpdate).sections.count else {
                return
            }
            let section = layout(at: .beforeUpdate).sections[sectionIndex]
            if section.locationHeight.rounded() <= minY {
                // Changing content offset for deleted items using `invalidateLayout(with:) causes UI glitches.
                // So we are using targetContentOffset(forProposedContentOffset:) which is going to be called after.
                proposedCompensatingOffset -= (section.height + interSectionSpacing)
            }
        }
    }

    private func offsetByCompensation(frame: inout CGRect,
                                      at itemPath: ItemPath,
                                      for state: ModelState,
                                      backward: Bool = false) {
        guard layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates,
              state == .afterUpdate,
              isLayoutBiggerThanVisibleBounds(at: .afterUpdate) else {
            return
        }
        frame.offsettingBy(dx: 0, dy: proposedCompensatingOffset * (backward ? -1 : 1))
    }

}
