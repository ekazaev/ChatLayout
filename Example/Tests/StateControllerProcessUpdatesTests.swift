//
// ChatLayout
// StateControllerProcessUpdatesTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

@testable import ChatLayout
import XCTest

@MainActor
final class StateControllerProcessUpdatesTests: XCTestCase {
    func testHeightAndItems() throws {
        let layout = preparedLayout(sectionCounts: [100, 100, 100])

        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), expectedContentHeight(sectionHeights: [
            sectionHeight(itemHeights: Array(repeating: CGFloat(40), count: 100)),
            sectionHeight(itemHeights: Array(repeating: CGFloat(40), count: 100)),
            sectionHeight(itemHeights: Array(repeating: CGFloat(40), count: 100))
        ]))

        for sectionIndex in 0..<3 {
            XCTAssertEqual(layout.controller.numberOfItems(in: sectionIndex, at: .beforeUpdate), 100)
            for itemIndex in 0..<100 {
                let itemPath = ItemPath(item: itemIndex, section: sectionIndex)
                let item = try XCTUnwrap(layout.controller.item(for: itemPath, at: .beforeUpdate))
                let attributes = try XCTUnwrap(layout.controller.itemAttributes(for: itemPath, at: .beforeUpdate))
                XCTAssertEqual(item.size, CGSize(width: 300, height: 40))
                XCTAssertEqual(attributes.size, CGSize(width: 300, height: 40))
            }
        }

        XCTAssertNil(layout.controller.item(for: ItemPath(item: 0, section: 3), at: .beforeUpdate))
    }

    func testItemReloadUsesLatestConfiguration() throws {
        let layout = preparedLayout(sectionCounts: [3])
        let reloadedIdentifier = try itemIdentifier(in: layout, item: 1, section: 0, state: .beforeUpdate)

        layout.preferredSizeAtIndexPath[IndexPath(item: 1, section: 0)] = CGSize(width: 300, height: 80)
        layout.calculatedSizeAtIndexPath[IndexPath(item: 1, section: 0)] = CGSize(width: 300, height: 80)

        layout.controller.process(changeItems: [
            .itemReload(itemIndexPath: IndexPath(item: 1, section: 0))
        ])

        XCTAssertEqual(layout.controller.contentHeight(at: .afterUpdate), 174)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 1, section: 0, state: .afterUpdate), reloadedIdentifier)
        XCTAssertEqual(
            try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 1, section: 0), at: .afterUpdate)).size,
            CGSize(width: 300, height: 80)
        )
        XCTAssertEqual(
            try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 2, section: 0), at: .afterUpdate)).minY,
            134
        )

        layout.controller.commitUpdates()
        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), 174)
    }

    func testSectionReloadRebuildsSectionModels() throws {
        let layout = preparedLayout(sectionCounts: [2, 3])
        let firstSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 0, state: .beforeUpdate)
        let firstSectionSecondItem = try itemIdentifier(in: layout, item: 1, section: 0, state: .beforeUpdate)
        let secondSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 1, state: .beforeUpdate)

        layout.setSections([3, 1])
        layout.preferredSizeAtIndexPath[IndexPath(item: 0, section: 0)] = CGSize(width: 300, height: 50)
        layout.calculatedSizeAtIndexPath[IndexPath(item: 0, section: 0)] = CGSize(width: 300, height: 50)
        layout.preferredSizeAtIndexPath[IndexPath(item: 2, section: 0)] = CGSize(width: 300, height: 60)
        layout.calculatedSizeAtIndexPath[IndexPath(item: 2, section: 0)] = CGSize(width: 300, height: 60)
        layout.preferredSizeAtIndexPath[IndexPath(item: 0, section: 1)] = CGSize(width: 300, height: 55)
        layout.calculatedSizeAtIndexPath[IndexPath(item: 0, section: 1)] = CGSize(width: 300, height: 55)

        layout.controller.process(changeItems: [
            .sectionReload(sectionIndex: 0),
            .sectionReload(sectionIndex: 1)
        ])

        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .afterUpdate), 1)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 0, state: .afterUpdate), firstSectionFirstItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 1, section: 0, state: .afterUpdate), firstSectionSecondItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 1, state: .afterUpdate), secondSectionFirstItem)
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 1), at: .afterUpdate))
        XCTAssertEqual(layout.controller.contentHeight(at: .afterUpdate), 222)
        XCTAssertEqual(
            try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), at: .afterUpdate)).size,
            CGSize(width: 300, height: 50)
        )
        XCTAssertEqual(
            try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 2, section: 0), at: .afterUpdate)).size,
            CGSize(width: 300, height: 60)
        )
        XCTAssertEqual(
            try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 0, section: 1), at: .afterUpdate)).size,
            CGSize(width: 300, height: 55)
        )
    }

    func testItemInsertionPreservesExistingIdentifiers() throws {
        let layout = preparedLayout(sectionCounts: [2, 2, 0])
        let lastFirstSectionItem = try itemIdentifier(in: layout, item: 1, section: 0, state: .beforeUpdate)
        let firstSecondSectionItem = try itemIdentifier(in: layout, item: 0, section: 1, state: .beforeUpdate)
        let contentHeightBefore = layout.controller.contentHeight(at: .beforeUpdate)

        layout.controller.process(changeItems: [
            .itemInsert(itemIndexPath: IndexPath(item: 2, section: 0)),
            .itemInsert(itemIndexPath: IndexPath(item: 0, section: 1)),
            .itemInsert(itemIndexPath: IndexPath(item: 0, section: 2)),
            .itemInsert(itemIndexPath: IndexPath(item: 1, section: 2))
        ])

        XCTAssertEqual(layout.controller.contentHeight(at: .afterUpdate), contentHeightBefore + 181)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 1, section: 0, state: .afterUpdate), lastFirstSectionItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 1, section: 1, state: .afterUpdate), firstSecondSectionItem)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .afterUpdate), 2)
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 2), at: .afterUpdate))
    }

    func testSectionInsertPreservesMovedSectionIdentifiers() throws {
        let layout = preparedLayout(sectionCounts: [2, 2, 2])
        let firstSectionIdentifier = try sectionIdentifier(in: layout, section: 0, state: .beforeUpdate)
        let secondSectionIdentifier = try sectionIdentifier(in: layout, section: 1, state: .beforeUpdate)
        let thirdSectionIdentifier = try sectionIdentifier(in: layout, section: 2, state: .beforeUpdate)
        let secondSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 1, state: .beforeUpdate)
        let thirdSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 2, state: .beforeUpdate)

        layout.setSections([2, 1, 3, 2, 2])
        layout.controller.process(changeItems: [
            .sectionInsert(sectionIndex: 1),
            .sectionInsert(sectionIndex: 2)
        ])

        XCTAssertEqual(layout.controller.numberOfSections(at: .afterUpdate), 5)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 2)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .afterUpdate), 1)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .afterUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 3, at: .afterUpdate), 2)
        XCTAssertEqual(layout.controller.numberOfItems(in: 4, at: .afterUpdate), 2)
        XCTAssertEqual(try sectionIdentifier(in: layout, section: 0, state: .afterUpdate), firstSectionIdentifier)
        XCTAssertEqual(try sectionIdentifier(in: layout, section: 3, state: .afterUpdate), secondSectionIdentifier)
        XCTAssertEqual(try sectionIdentifier(in: layout, section: 4, state: .afterUpdate), thirdSectionIdentifier)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 3, state: .afterUpdate), secondSectionFirstItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 4, state: .afterUpdate), thirdSectionFirstItem)
    }

    func testItemDeletionRemovesItemsAndShiftsRemainingIdentifiers() throws {
        let layout = preparedLayout(sectionCounts: [2, 2, 1])
        let firstSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 0, state: .beforeUpdate)
        let secondSectionLastItem = try itemIdentifier(in: layout, item: 1, section: 1, state: .beforeUpdate)
        let contentHeightBefore = layout.controller.contentHeight(at: .beforeUpdate)

        layout.controller.process(changeItems: [
            .itemDelete(itemIndexPath: IndexPath(item: 1, section: 0)),
            .itemDelete(itemIndexPath: IndexPath(item: 0, section: 1)),
            .itemDelete(itemIndexPath: IndexPath(item: 0, section: 2))
        ])

        XCTAssertEqual(layout.controller.contentHeight(at: .afterUpdate), contentHeightBefore - 134)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 1)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .afterUpdate), 1)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .afterUpdate), 0)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 0, state: .afterUpdate), firstSectionFirstItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 1, state: .afterUpdate), secondSectionLastItem)
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), at: .afterUpdate))
    }

    func testSectionDeleteRemovesSectionsAndKeepsRemainingIdentifiers() throws {
        let layout = preparedLayout(sectionCounts: [2, 2, 2])
        let remainingSectionIdentifier = try sectionIdentifier(in: layout, section: 1, state: .beforeUpdate)
        let remainingItemIdentifier = try itemIdentifier(in: layout, item: 0, section: 1, state: .beforeUpdate)

        layout.controller.process(changeItems: [
            .sectionDelete(sectionIndex: 0),
            .sectionDelete(sectionIndex: 2)
        ])

        XCTAssertEqual(layout.controller.numberOfSections(at: .afterUpdate), 1)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 2)
        XCTAssertEqual(try sectionIdentifier(in: layout, section: 0, state: .afterUpdate), remainingSectionIdentifier)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 0, state: .afterUpdate), remainingItemIdentifier)
        XCTAssertEqual(layout.controller.contentHeight(at: .afterUpdate), 87)
    }

    func testItemMoveUpdatesIdentifiersAndPaths() throws {
        let layout = preparedLayout(sectionCounts: [3, 3, 1])
        let movedFromFirstSection = try itemIdentifier(in: layout, item: 0, section: 0, state: .beforeUpdate)
        let untouchedFirstSectionItem = try itemIdentifier(in: layout, item: 1, section: 0, state: .beforeUpdate)
        let movedWithinSecondSection = try itemIdentifier(in: layout, item: 0, section: 1, state: .beforeUpdate)
        let movedFromThirdSection = try itemIdentifier(in: layout, item: 0, section: 2, state: .beforeUpdate)
        let contentHeightBefore = layout.controller.contentHeight(at: .beforeUpdate)

        layout.controller.process(changeItems: [
            .itemMove(initialItemIndexPath: IndexPath(item: 0, section: 0), finalItemIndexPath: IndexPath(item: 0, section: 2)),
            .itemMove(initialItemIndexPath: IndexPath(item: 0, section: 1), finalItemIndexPath: IndexPath(item: 1, section: 1)),
            .itemMove(initialItemIndexPath: IndexPath(item: 0, section: 2), finalItemIndexPath: IndexPath(item: 0, section: 0))
        ])

        XCTAssertEqual(layout.controller.contentHeight(at: .afterUpdate), contentHeightBefore)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 0, state: .afterUpdate), movedFromThirdSection)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 1, section: 0, state: .afterUpdate), untouchedFirstSectionItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 1, section: 1, state: .afterUpdate), movedWithinSecondSection)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 2, state: .afterUpdate), movedFromFirstSection)
        XCTAssertEqual(layout.controller.itemPath(by: movedFromFirstSection, at: .afterUpdate), ItemPath(item: 0, section: 2))
        XCTAssertEqual(layout.controller.itemPath(by: movedFromThirdSection, at: .afterUpdate), ItemPath(item: 0, section: 0))
    }

    func testSectionMoveReordersSections() throws {
        let layout = preparedLayout(sectionCounts: [2, 3, 4])
        let firstSectionIdentifier = try sectionIdentifier(in: layout, section: 0, state: .beforeUpdate)
        let secondSectionIdentifier = try sectionIdentifier(in: layout, section: 1, state: .beforeUpdate)
        let thirdSectionIdentifier = try sectionIdentifier(in: layout, section: 2, state: .beforeUpdate)
        let firstSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 0, state: .beforeUpdate)
        let secondSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 1, state: .beforeUpdate)
        let thirdSectionFirstItem = try itemIdentifier(in: layout, item: 0, section: 2, state: .beforeUpdate)

        layout.controller.process(changeItems: [
            .sectionMove(initialSectionIndex: 0, finalSectionIndex: 1),
            .sectionMove(initialSectionIndex: 2, finalSectionIndex: 0)
        ])

        XCTAssertEqual(layout.controller.numberOfSections(at: .afterUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 4)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .afterUpdate), 2)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .afterUpdate), 3)
        XCTAssertEqual(try sectionIdentifier(in: layout, section: 0, state: .afterUpdate), thirdSectionIdentifier)
        XCTAssertEqual(try sectionIdentifier(in: layout, section: 1, state: .afterUpdate), firstSectionIdentifier)
        XCTAssertEqual(try sectionIdentifier(in: layout, section: 2, state: .afterUpdate), secondSectionIdentifier)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 0, state: .afterUpdate), thirdSectionFirstItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 1, state: .afterUpdate), firstSectionFirstItem)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 2, state: .afterUpdate), secondSectionFirstItem)
    }

    func testDeleteReloadProcessOrder() throws {
        let layout = preparedLayout(sectionCounts: [3])
        let survivingItemIdentifier = try itemIdentifier(in: layout, item: 2, section: 0, state: .beforeUpdate)
        layout.preferredSizeAtIndexPath[IndexPath(item: 0, section: 0)] = CGSize(width: 300, height: 80)
        layout.calculatedSizeAtIndexPath[IndexPath(item: 0, section: 0)] = CGSize(width: 300, height: 80)

        layout.controller.process(changeItems: [
            .itemDelete(itemIndexPath: IndexPath(item: 0, section: 0)),
            .itemDelete(itemIndexPath: IndexPath(item: 1, section: 0)),
            .itemReload(itemIndexPath: IndexPath(item: 2, section: 0))
        ])

        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 1)
        XCTAssertEqual(layout.controller.reloadedIndexes, Set([IndexPath(item: 0, section: 0)]))
        XCTAssertEqual(try itemIdentifier(in: layout, item: 0, section: 0, state: .afterUpdate), survivingItemIdentifier)
        XCTAssertEqual(
            try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), at: .afterUpdate)).size,
            CGSize(width: 300, height: 80)
        )
    }

    func testDeleteInsertProcessOrder() throws {
        let layout = preparedLayout(sectionCounts: [3])
        let survivingItemIdentifier = try itemIdentifier(in: layout, item: 2, section: 0, state: .beforeUpdate)

        layout.controller.process(changeItems: [
            .itemDelete(itemIndexPath: IndexPath(item: 0, section: 0)),
            .itemDelete(itemIndexPath: IndexPath(item: 1, section: 0)),
            .itemInsert(itemIndexPath: IndexPath(item: 0, section: 0))
        ])

        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 2)
        XCTAssertEqual(try itemIdentifier(in: layout, item: 1, section: 0, state: .afterUpdate), survivingItemIdentifier)
    }

    func testMoveInsertReloadProcessOrder() {
        let layout = preparedLayout(sectionCounts: [3])

        layout.controller.process(changeItems: [
            .itemMove(initialItemIndexPath: IndexPath(item: 2, section: 0), finalItemIndexPath: IndexPath(item: 0, section: 0)),
            .itemInsert(itemIndexPath: IndexPath(item: 0, section: 0)),
            .itemReload(itemIndexPath: IndexPath(item: 0, section: 0))
        ])

        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 4)
        XCTAssertEqual(layout.controller.reloadedIndexes, Set([IndexPath(item: 2, section: 0)]))
    }

    func testPinnedTopItem() throws {
        let layout = MockCollectionLayout()
        layout.setSections([100])
        layout.visibleBounds.origin.y = 400
        layout.pinningTypeAtIndexPath[IndexPath(item: 0, section: 0)] = .top
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        layout.controller.updatePinnedInfo(at: .beforeUpdate)

        let item = try XCTUnwrap(
            layout.controller.itemAttributes(
                for: ItemPath(item: 0, section: 0),
                at: .beforeUpdate,
                withPinnning: true
            )
        )
        XCTAssertEqual(item.frame.minY, 400)
    }

    func testPinnedBottomItem() throws {
        let layout = MockCollectionLayout()
        layout.setSections([100])
        layout.pinningTypeAtIndexPath[IndexPath(item: 99, section: 0)] = .bottom
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        layout.controller.updatePinnedInfo(at: .beforeUpdate)

        let item = try XCTUnwrap(
            layout.controller.itemAttributes(
                for: ItemPath(item: 99, section: 0),
                at: .beforeUpdate,
                withPinnning: true
            )
        )
        XCTAssertEqual(item.frame.minY, layout.visibleBounds.maxY - item.frame.height)
    }

    private func preparedLayout(sectionCounts: [Int]) -> MockCollectionLayout {
        let layout = MockCollectionLayout()
        layout.setSections(sectionCounts)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        return layout
    }

    private func itemIdentifier(
        in layout: MockCollectionLayout,
        item: Int,
        section: Int,
        state: ModelState
    ) throws -> UUID {
        try XCTUnwrap(layout.controller.itemIdentifier(for: ItemPath(item: item, section: section), at: state))
    }

    private func sectionIdentifier(
        in layout: MockCollectionLayout,
        section: Int,
        state: ModelState
    ) throws -> UUID {
        try XCTUnwrap(layout.controller.sectionIdentifier(for: section, at: state))
    }

    private func sectionHeight(itemHeights: [CGFloat], spacing: CGFloat = 7) -> CGFloat {
        guard !itemHeights.isEmpty else {
            return 0
        }
        return itemHeights.reduce(0, +) + CGFloat(itemHeights.count - 1) * spacing
    }

    private func expectedContentHeight(
        sectionHeights: [CGFloat],
        interSectionSpacing: CGFloat = 3,
        additionalInsets: UIEdgeInsets = .zero
    ) -> CGFloat {
        let totalSectionSpacing = CGFloat(max(sectionHeights.count - 1, 0)) * interSectionSpacing
        return additionalInsets.top + additionalInsets.bottom + sectionHeights.reduce(0, +) + totalSectionSpacing
    }
}
