//
// ChatLayout
// StateController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
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

    var keepContentAtBottomOfVisibleArea: Bool { get }

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

    private struct ItemToRestore {
        var globalIndex: Int
        var kind: ItemKind
        var offset: CGFloat
    }

    private enum GlobalIndexModel {
        case beforeUpdate
        case model(LayoutModel<Layout>)

        var layout: LayoutModel<Layout>? {
            guard case let .model(layout) = self else {
                return nil
            }
            return layout
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

    private(set) var reconfiguredIndexes: Set<IndexPath> = []

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
        for state in ModelState.allCases {
            resetCachedAttributeObjects(at: state)
        }
    }

    private func resetCachedAttributeObjects(at state: ModelState) {
        cachedAttributeObjects[state] = [:]
        for kind in ItemKind.allCases {
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
            attributes.interItemSpacing = item.interItemSpacing
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
            attributes.interItemSpacing = item.interItemSpacing
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
            attributes.interItemSpacing = item.interItemSpacing
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
        if layoutRepresentation.keepContentAtBottomOfVisibleArea == true,
           !(kind == .header && itemPath.section == 0),
           !isLayoutBiggerThanVisibleBounds(at: state, withFullCompensation: false, visibleBounds: visibleBounds) {
            itemFrame.offsettingBy(dx: 0, dy: visibleBounds.height.rounded() - contentSize(for: state).height.rounded())
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
        case .footer,
             .header:
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

        let isLastItemInSection = isLastItemInSection(itemPath, at: state)
        let frameUpdateAction = CompensatingAction.frameUpdate(previousFrame: previousFrame,
                                                               newFrame: item.frame,
                                                               previousSpacing: isLastItemInSection ? 0 : previousInterItemSpacing,
                                                               newSpacing: isLastItemInSection ? 0 : interItemSpacing)
        compensateOffsetIfNeeded(for: itemPath, kind: kind, action: frameUpdateAction)
    }

    func process(changeItems: [ChangeItem]) {
        func applyConfiguration(_ configuration: ItemModel.Configuration, to item: inout ItemModel) {
            item.alignment = configuration.alignment
            item.interItemSpacing = configuration.interItemSpacing
            if let calculatedSize = configuration.calculatedSize {
                item.calculatedSize = calculatedSize
                item.calculatedOnce = true
            } else {
                item.resetSize()
            }
        }
        var itemToRestore: ItemToRestore?
        if layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates,
           let lastVisibleAttribute = allAttributes(at: .beforeUpdate, visibleRect: layoutRepresentation.visibleBounds).last,
           let itemFrame = itemFrame(for: lastVisibleAttribute.indexPath.itemPath, kind: lastVisibleAttribute.kind, at: .beforeUpdate) {
            itemToRestore = ItemToRestore(globalIndex: globalIndexFor(lastVisibleAttribute.indexPath.itemPath, kind: lastVisibleAttribute.kind, state: .beforeUpdate),
                                          kind: lastVisibleAttribute.kind,
                                          offset: (itemFrame.maxY - layoutRepresentation.visibleBounds.maxY).rounded())
        }
        batchUpdateCompensatingOffset = 0
        proposedCompensatingOffset = 0

        var afterUpdateModel = LayoutModel(sections: layoutBeforeUpdate.sections,
                                           collectionLayout: layoutRepresentation)
        resetCachedAttributeObjects()

        var reloadedSectionsIndexesArray = [Int]()
        var deletedSectionsIndexesArray = [Int]()
        var insertedSectionsIndexesArray = [(Int, SectionModel<Layout>?)]()

        var reloadedItemsIndexesArray = [IndexPath]()
        var reconfiguredItemsIndexesArray = [IndexPath]()
        var deletedItemsIndexesArray = [IndexPath]()
        var insertedItemsIndexesArray = [(IndexPath, ItemModel?)]()

        var visibleBoundsBeforeUpdate = layoutRepresentation.visibleBounds

        for item in changeItems {
            switch item {
            case let .sectionReload(sectionIndex):
                reloadedSectionsIndexes.insert(sectionIndex)

                reloadedSectionsIndexesArray.append(sectionIndex)
            case let .itemReload(itemIndexPath: indexPath):
                reloadedItemsIndexesArray.append(indexPath)
            case let .itemReconfigure(itemIndexPath: indexPath):
                reconfiguredItemsIndexesArray.append(indexPath)
            case let .sectionDelete(sectionIndex):
                deletedSectionsIndexes.insert(sectionIndex)

                deletedSectionsIndexesArray.append(sectionIndex)
            case let .itemDelete(itemIndexPath: indexPath):
                deletedIndexes.insert(indexPath)

                deletedItemsIndexesArray.append(indexPath)
            case let .sectionInsert(sectionIndex):
                insertedSectionsIndexes.insert(sectionIndex)

                insertedSectionsIndexesArray.append((sectionIndex, nil))
            case let .itemInsert(itemIndexPath: indexPath):
                insertedIndexes.insert(indexPath)

                insertedItemsIndexesArray.append((indexPath, nil))
            case let .sectionMove(initialSectionIndex, finalSectionIndex):
                movedSectionsIndexes.insert(initialSectionIndex)

                let original = layoutBeforeUpdate.sections[initialSectionIndex]
                deletedSectionsIndexesArray.append(initialSectionIndex)
                insertedSectionsIndexesArray.append((finalSectionIndex, original))
            case let .itemMove(initialItemIndexPath, finalItemIndexPath):
                movedIndexes.insert(initialItemIndexPath)

                let original = layoutBeforeUpdate.sections[initialItemIndexPath.section].items[initialItemIndexPath.item]
                deletedItemsIndexesArray.append(initialItemIndexPath)
                insertedItemsIndexesArray.append((finalItemIndexPath, original))
            }
        }

        deletedSectionsIndexesArray = deletedSectionsIndexesArray.sorted(by: { $0 > $1 })
        insertedSectionsIndexesArray = insertedSectionsIndexesArray.sorted(by: { $0.0 < $1.0 })

        deletedItemsIndexesArray = deletedItemsIndexesArray.sorted(by: { $0 > $1 })
        insertedItemsIndexesArray = insertedItemsIndexesArray.sorted(by: { $0.0 < $1.0 })

        for sectionIndex in reloadedSectionsIndexesArray {
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
        }

        for sectionIndex in deletedSectionsIndexesArray {
            afterUpdateModel.removeSection(for: sectionIndex)
            if layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates {
                if let localItemToRestore = itemToRestore {
                    guard let originalIndexPath = itemPathFor(localItemToRestore.globalIndex, kind: localItemToRestore.kind, state: .beforeUpdate) else {
                        continue
                    }
                    if originalIndexPath.section >= sectionIndex {
                        if originalIndexPath.section != 0 {
                            if originalIndexPath.section == sectionIndex {
                                let previousSectionIndex = sectionIndex - 1
                                let previousSection = section(at: previousSectionIndex, at: .beforeUpdate)
                                if previousSection.footer != nil {
                                    itemToRestore?.kind = .footer
                                    itemToRestore?.globalIndex = globalIndexFor(ItemPath(item: 0, section: previousSectionIndex), kind: .footer, state: .model(afterUpdateModel))
                                } else if !previousSection.items.isEmpty {
                                    itemToRestore?.kind = .cell
                                    itemToRestore?.globalIndex = globalIndexFor(ItemPath(item: previousSection.items.count - 1, section: previousSectionIndex), kind: .cell, state: .model(afterUpdateModel))
                                } else if previousSection.header != nil {
                                    itemToRestore?.kind = .header
                                    itemToRestore?.globalIndex = globalIndexFor(ItemPath(item: 0, section: previousSectionIndex), kind: .header, state: .model(afterUpdateModel))
                                } else {
                                    itemToRestore = nil
                                }
                            } else {
                                let section = section(at: sectionIndex, at: .beforeUpdate)
                                itemToRestore?.globalIndex = localItemToRestore.globalIndex - section.items.count
                            }
                        } else {
                            itemToRestore = nil
                        }
                    }
                }
            }
        }

        for (sectionIndex, section) in insertedSectionsIndexesArray {
            let insertedSection: SectionModel<Layout>
            if let section {
                insertedSection = section
                afterUpdateModel.insertSection(section, at: sectionIndex)
            } else {
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
                insertedSection = section
                afterUpdateModel.insertSection(section, at: sectionIndex)
            }
            if layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates {
                if let localItemToRestore = itemToRestore {
                    guard let originalIndexPath = itemPathFor(localItemToRestore.globalIndex, kind: localItemToRestore.kind, state: .model(afterUpdateModel)) else {
                        continue
                    }
                    if localItemToRestore.globalIndex >= originalIndexPath.section {
                        itemToRestore?.globalIndex = localItemToRestore.globalIndex + insertedSection.items.count
                    }
                } else {
                    if insertedSection.footer != nil {
                        itemToRestore?.kind = .footer
                        itemToRestore?.globalIndex = globalIndexFor(ItemPath(item: 0, section: sectionIndex), kind: .footer, state: .model(afterUpdateModel))
                    } else if !insertedSection.items.isEmpty {
                        itemToRestore?.kind = .cell
                        itemToRestore?.globalIndex = globalIndexFor(ItemPath(item: insertedSection.items.count - 1, section: sectionIndex), kind: .cell, state: .model(afterUpdateModel))
                    } else if insertedSection.header != nil {
                        itemToRestore?.kind = .header
                        itemToRestore?.globalIndex = globalIndexFor(ItemPath(item: 0, section: sectionIndex), kind: .header, state: .model(afterUpdateModel))
                    } else {
                        itemToRestore = nil
                    }
                }
            }
        }

        for indexPath in deletedItemsIndexesArray {
            guard let itemId = itemIdentifier(for: indexPath.itemPath, kind: .cell, at: .beforeUpdate) else {
                assertionFailure("Item at index path (\(indexPath.section) - \(indexPath.item)) does not exist.")
                continue
            }
            afterUpdateModel.removeItem(by: itemId)
            if layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates {
                let globalIndex = globalIndexFor(indexPath.itemPath, kind: .cell, state: .beforeUpdate)
                if let localItemToRestore = itemToRestore,
                   localItemToRestore.kind == .cell,
                   localItemToRestore.globalIndex >= globalIndex {
                    if localItemToRestore.globalIndex != 0 {
                        itemToRestore?.globalIndex = localItemToRestore.globalIndex - 1
                    } else {
                        itemToRestore = nil
                    }
                }
            }
        }

        for (indexPath, item) in insertedItemsIndexesArray {
            if let item {
                afterUpdateModel.insertItem(item, at: indexPath)
                visibleBoundsBeforeUpdate.offsettingBy(dx: 0, dy: item.frame.height)
            } else {
                let item = ItemModel(with: layoutRepresentation.configuration(for: .cell, at: indexPath))
                visibleBoundsBeforeUpdate.offsettingBy(dx: 0, dy: item.frame.height)
                afterUpdateModel.insertItem(item, at: indexPath)
            }
            if layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates {
                let globalIndex = globalIndexFor(indexPath.itemPath, kind: .cell, state: .model(afterUpdateModel))
                if let localItemToRestore = itemToRestore {
                    if localItemToRestore.kind == .cell,
                       globalIndex <= localItemToRestore.globalIndex + 1 {
                        itemToRestore?.globalIndex = localItemToRestore.globalIndex + 1
                    }
                } else {
                    itemToRestore = ItemToRestore(globalIndex: globalIndex, kind: .cell, offset: 0)
                }
            }
        }

        for indexPath in reloadedItemsIndexesArray {
            guard var item = item(for: indexPath.itemPath, kind: .cell, at: .beforeUpdate),
                  let indexPathAfterUpdate = afterUpdateModel.itemPath(by: item.id, kind: .cell)?.indexPath else {
                assertionFailure("Item at index path (\(indexPath.section) - \(indexPath.item)) does not exist.")
                continue
            }
            reloadedIndexes.insert(indexPathAfterUpdate)
            let oldHeight = item.frame.height
            let configuration = layoutRepresentation.configuration(for: .cell, at: indexPathAfterUpdate)
            applyConfiguration(configuration, to: &item)
            afterUpdateModel.replaceItem(item, at: indexPathAfterUpdate)
            visibleBoundsBeforeUpdate.offsettingBy(dx: 0, dy: item.frame.height - oldHeight)
        }

        for indexPath in reconfiguredItemsIndexesArray {
            guard var item = item(for: indexPath.itemPath, kind: .cell, at: .beforeUpdate),
                  let indexPathAfterUpdate = afterUpdateModel.itemPath(by: item.id, kind: .cell)?.indexPath else {
                assertionFailure("Item at index path (\(indexPath.section) - \(indexPath.item)) does not exist.")
                continue
            }
            reconfiguredIndexes.insert(indexPathAfterUpdate)

            let oldHeight = item.frame.height
            let configuration = layoutRepresentation.configuration(for: .cell, at: indexPathAfterUpdate)
            applyConfiguration(configuration, to: &item)
            afterUpdateModel.replaceItem(item, at: indexPathAfterUpdate)
            visibleBoundsBeforeUpdate.offsettingBy(dx: 0, dy: item.frame.height - oldHeight)
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

        // Calculating potential content offset changes after the updates
        if layoutRepresentation.keepContentOffsetAtBottomOnBatchUpdates,
           let itemToRestore,
           let itemPath = itemPathFor(itemToRestore.globalIndex, kind: itemToRestore.kind, state: .model(afterUpdateModel)),
           let itemFrame = itemFrame(for: itemPath, kind: itemToRestore.kind, at: .afterUpdate),
           isLayoutBiggerThanVisibleBounds(at: .afterUpdate, visibleBounds: layoutRepresentation.visibleBounds) {
            let newProposedCompensationOffset = (itemFrame.maxY - itemToRestore.offset) - layoutRepresentation.visibleBounds.maxY
            proposedCompensatingOffset = newProposedCompensationOffset
        }
        totalProposedCompensatingOffset = proposedCompensatingOffset
    }

    func commitUpdates() {
        insertedIndexes = []
        insertedSectionsIndexes = []

        reloadedIndexes = []
        reconfiguredIndexes = []
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
            for (sectionIndex, section) in layout.sections.enumerated() {
                let sectionPath = ItemPath(item: 0, section: sectionIndex)
                if let headerAttributes = itemAttributes(for: sectionPath, kind: .header, at: state, additionalAttributes: additionalAttributes) {
                    attributes.append(headerAttributes)
                }
                if let footerAttributes = itemAttributes(for: sectionPath, kind: .footer, at: state, additionalAttributes: additionalAttributes) {
                    attributes.append(footerAttributes)
                }
                for itemIndex in 0..<section.items.count {
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
            if (itemFrame.minY - interItemSpacing).rounded() <= minY {
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

    private func isLastItemInSection(_ itemPath: ItemPath, at state: ModelState) -> Bool {
        let layout = layout(at: state)
        if itemPath.section < layout.sections.count,
           itemPath.item < layout.sections[itemPath.section].items.count - 1 {
            return false
        } else {
            return true
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

    private func globalIndexFor(_ itemPath: ItemPath, kind: ItemKind, state: GlobalIndexModel) -> Int {
        func numberOfItemsBeforeSection(_ sectionIndex: Int, state: GlobalIndexModel) -> Int {
            let layout = state.layout ?? layout(at: .beforeUpdate)
            var total = 0
            for index in 0..<max(sectionIndex, 0) {
                let section = layout.sections[index]
                total += section.items.count
            }
            return total
        }

        switch kind {
        case .header:
            return numberOfItemsBeforeSection(itemPath.section, state: state)
        case .footer:
            return numberOfItemsBeforeSection(itemPath.section, state: state)
        case .cell:
            return numberOfItemsBeforeSection(itemPath.section, state: state) + itemPath.item
        }
    }

    private func itemPathFor(_ globalIndex: Int, kind: ItemKind, state: GlobalIndexModel) -> ItemPath? {
        let layout = state.layout ?? layout(at: .beforeUpdate)
        var sectionIndex = 0
        var itemsCount = 0
        for index in 0..<layout.sections.count {
            sectionIndex = index
            let section = layout.sections[index]
            let countIncludingThisSection = itemsCount + section.items.count
            if countIncludingThisSection > globalIndex {
                break
            }
            itemsCount = countIncludingThisSection
        }
        guard sectionIndex < layout.sections.count,
              sectionIndex >= 0 else {
            assertionFailure("Internal inconsistency. Section index \(sectionIndex) is invalid. Amount of sections is \(layout.sections.count).")
            return nil
        }
        switch kind {
        case .header:
            let section = layout.sections[sectionIndex]
            guard section.header != nil else {
                assertionFailure("Internal inconsistency. Section index \(sectionIndex) does not have header.")
                return nil
            }
            return ItemPath(item: 0, section: sectionIndex)
        case .footer:
            let section = layout.sections[sectionIndex]
            guard section.footer != nil else {
                assertionFailure("Internal inconsistency. Section index \(sectionIndex) does not have footer.")
                return nil
            }
            return ItemPath(item: 0, section: sectionIndex)
        case .cell:
            let itemIndex = globalIndex - itemsCount
            let section = layout.sections[sectionIndex]
            guard itemIndex >= 0,
                  itemIndex < section.items.count else {
                assertionFailure("Internal inconsistency. Item index \(itemIndex) is invalid. Amount of items is \(section.items.count).")
                return nil
            }
            return ItemPath(item: itemIndex, section: sectionIndex)
        }
    }
}
