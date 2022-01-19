//
// ChatLayout
// StateControllerProcessUpdatesTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

@testable import ChatLayout
import XCTest

class StateControllerProcessUpdatesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHeight() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), layout.settings.estimatedItemSize!.height * (102 * 3) + layout.settings.interItemSpacing * (100 * 3) + layout.settings.interSectionSpacing * 2)

        for i in 0..<layout.numberOfItemsInSection.count {
            let header = layout.controller.item(for: ItemPath(item: 0, section: i), kind: .header, at: .beforeUpdate)
            let footer = layout.controller.item(for: ItemPath(item: 0, section: i), kind: .footer, at: .beforeUpdate)
            XCTAssertNotNil(header)
            XCTAssertNotNil(footer)
            XCTAssertEqual(header?.size, layout.settings.estimatedItemSize)
            XCTAssertEqual(footer?.size, layout.settings.estimatedItemSize)
            XCTAssertEqual(header?.size, layout.controller.itemAttributes(for: ItemPath(item: 0, section: i), kind: .header, at: .beforeUpdate)?.size)
            XCTAssertEqual(footer?.size, layout.controller.itemAttributes(for: ItemPath(item: 0, section: i), kind: .footer, at: .beforeUpdate)?.size)
            for j in 0..<100 {
                let item = layout.controller.item(for: ItemPath(item: j, section: i), kind: .cell, at: .beforeUpdate)
                XCTAssertNotNil(item)
                XCTAssertEqual(item?.size, layout.settings.estimatedItemSize)
                XCTAssertEqual(item?.size, layout.controller.itemAttributes(for: ItemPath(item: j, section: i), kind: .cell, at: .beforeUpdate)?.size)
            }
        }
        XCTAssertNil(layout.controller.item(for: ItemPath(item: 0, section: 5), kind: .header, at: .beforeUpdate))
        XCTAssertNil(layout.controller.item(for: ItemPath(item: 0, section: 5), kind: .footer, at: .beforeUpdate))
    }

    func testItemReload() {
        let layout = MockCollectionLayout()
        var changeItems: [ChangeItem] = []
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        for sectionIndex in 0..<layout.numberOfItemsInSection.count {
            for itemIndex in 0..<layout.numberOfItems(in: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let changeItem = ChangeItem.itemReload(itemIndexPath: indexPath)
                changeItems.append(changeItem)
            }
        }

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.controller.process(changeItems: changeItems)
        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), layout.controller.contentHeight(at: .afterUpdate))
        layout.controller.commitUpdates()

        layout.controller.process(changeItems: [.sectionReload(sectionIndex: 0),
                                                .sectionReload(sectionIndex: 1)])

        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), layout.controller.contentHeight(at: .afterUpdate))
        layout.controller.commitUpdates()
    }

    func testSectionReload() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var changeItems: [ChangeItem] = []
        changeItems.append(.sectionReload(sectionIndex: 0))
        changeItems.append(.sectionReload(sectionIndex: 1))
        changeItems.append(.sectionReload(sectionIndex: 2))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        layout.numberOfItemsInSection[1] = 50
        layout.controller.process(changeItems: changeItems)

        // Headers
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 200)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .afterUpdate), 50)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .afterUpdate), 100)

        // Frames
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 99, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 100, section: 0), kind: .cell, at: .afterUpdate)?.size, layout.settings.estimatedItemSize)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 49, section: 1), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))

        layout.controller.commitUpdates()
    }

    func testItemInsertion() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 0]
        var changeItems: [ChangeItem] = []
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), layout.settings.estimatedItemSize!.height * (102 + 102 + 2) + layout.settings.interItemSpacing * (100 + 100 + 0) + layout.settings.interSectionSpacing * 2)

        changeItems.append(.itemInsert(itemIndexPath: IndexPath(item: 100, section: 0)))
        changeItems.append(.itemInsert(itemIndexPath: IndexPath(item: 0, section: 1)))
        changeItems.append(.itemInsert(itemIndexPath: IndexPath(item: 0, section: 2)))
        changeItems.append(.itemInsert(itemIndexPath: IndexPath(item: 1, section: 2)))

        layout.controller.process(changeItems: changeItems)
        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate) + layout.settings.estimatedItemSize!.height * 4.0 + layout.settings.interItemSpacing * 4.0, layout.controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 99, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 99, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 2, section: 2), kind: .cell, at: .afterUpdate))
        layout.controller.commitUpdates()
    }

    func testSectionInsert() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var changeItems: [ChangeItem] = []
        changeItems.append(.sectionInsert(sectionIndex: 1))
        changeItems.append(.sectionInsert(sectionIndex: 2))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        layout.numberOfItemsInSection[1] = 50
        layout.numberOfItemsInSection[2] = 300
        layout.numberOfItemsInSection[4] = 100
        layout.controller.process(changeItems: changeItems)

        // Headers
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .afterUpdate), 50)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .afterUpdate), 300)
        XCTAssertEqual(layout.controller.numberOfItems(in: 3, at: .afterUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 4, at: .afterUpdate), 100)

        // Frames
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 99, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 49, section: 1), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 49, section: 1), kind: .cell, at: .afterUpdate)?.size, layout.settings.estimatedItemSize)

        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 3), kind: .cell, at: .afterUpdate))

        layout.controller.commitUpdates()
    }

    func testItemDeletion() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 1]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var changeItems: [ChangeItem] = []
        changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: 99, section: 0)))
        changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: 0, section: 1)))
        changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: 0, section: 2)))

        layout.controller.process(changeItems: changeItems)
        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate) - layout.settings.estimatedItemSize!.height * 3.0 - layout.settings.interItemSpacing * 3.0, layout.controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 98, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 98, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 2, section: 2), kind: .cell, at: .afterUpdate))
        layout.controller.commitUpdates()
    }

    func testSectionDelete() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var changeItems: [ChangeItem] = []
        changeItems.append(.sectionDelete(sectionIndex: 0))
        changeItems.append(.sectionDelete(sectionIndex: 2))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        layout.controller.process(changeItems: changeItems)

        // Headers
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfSections(at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfSections(at: .afterUpdate), 1)

        // Frames
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))

        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))

        layout.controller.commitUpdates()
    }

    func testItemMove() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 1]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var changeItems: [ChangeItem] = []
        changeItems.append(.itemMove(initialItemIndexPath: IndexPath(item: 0, section: 0), finalItemIndexPath: IndexPath(item: 0, section: 2)))
        changeItems.append(.itemMove(initialItemIndexPath: IndexPath(item: 0, section: 1), finalItemIndexPath: IndexPath(item: 1, section: 1)))
        changeItems.append(.itemMove(initialItemIndexPath: IndexPath(item: 0, section: 2), finalItemIndexPath: IndexPath(item: 0, section: 0)))

        layout.controller.process(changeItems: changeItems)
        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), layout.controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 2, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 2, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemPath(by: layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate)!,
                                                  kind: .cell,
                                                  at: .afterUpdate),
                       ItemPath(item: 0, section: 0))
        XCTAssertEqual(layout.controller.itemPath(by: layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)!,
                                                  kind: .cell,
                                                  at: .afterUpdate),
                       ItemPath(item: 0, section: 2))
        layout.controller.commitUpdates()
    }

    func testSectionMove() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection[0] = 100
        layout.numberOfItemsInSection[1] = 200
        layout.numberOfItemsInSection[2] = 300
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var changeItems: [ChangeItem] = []
        changeItems.append(.sectionMove(initialSectionIndex: 0, finalSectionIndex: 1))
        changeItems.append(.sectionMove(initialSectionIndex: 2, finalSectionIndex: 0))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        layout.controller.process(changeItems: changeItems)

        // Headers
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 300)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .beforeUpdate), 200)
        XCTAssertEqual(layout.controller.numberOfItems(in: 1, at: .afterUpdate), 200)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .beforeUpdate), 300)
        XCTAssertEqual(layout.controller.numberOfItems(in: 2, at: .afterUpdate), 100)
        XCTAssertEqual(layout.controller.numberOfSections(at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfSections(at: .afterUpdate), 3)

        // Frames
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))

        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 1), kind: .cell, at: .afterUpdate))

        layout.controller.commitUpdates()
    }

    func testDeleteReloadProcessOrder() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 3]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        var changeItems: [ChangeItem] = []
        changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: 0, section: 0)))
        changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: 1, section: 0)))
        changeItems.append(.itemReload(itemIndexPath: IndexPath(item: 2, section: 0)))
        layout.controller.process(changeItems: changeItems)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 1)
    }

    func testDeleteInsertProcessOrder() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 3]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        var changeItems: [ChangeItem] = []
        changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: 0, section: 0)))
        changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: 1, section: 0)))
        changeItems.append(.itemInsert(itemIndexPath: IndexPath(item: 0, section: 0)))
        layout.controller.process(changeItems: changeItems)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 2)
    }

    func testMoveInsertReloadProcessOrder() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 3]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        var changeItems: [ChangeItem] = []
        changeItems.append(.itemMove(initialItemIndexPath: IndexPath(item: 2, section: 0), finalItemIndexPath: IndexPath(item: 0, section: 0)))
        changeItems.append(.itemInsert(itemIndexPath: IndexPath(item: 0, section: 0)))
        changeItems.append(.itemReload(itemIndexPath: IndexPath(item: 0, section: 0)))
        layout.controller.process(changeItems: changeItems)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .beforeUpdate), 3)
        XCTAssertEqual(layout.controller.numberOfItems(in: 0, at: .afterUpdate), 4)
    }

    func testInsertionPerformance() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 0]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        var changeItems: [ChangeItem] = []
        for i in 0..<10000 {
            changeItems.append(.itemInsert(itemIndexPath: IndexPath(item: i, section: 0)))
        }
        measure {
            layout.controller.process(changeItems: changeItems)
        }
        layout.controller.commitUpdates()
    }

    func testReloadPerformance() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 1000]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        var changeItems: [ChangeItem] = []
        for i in 0..<1000 {
            changeItems.append(.itemReload(itemIndexPath: IndexPath(item: i, section: 0)))
        }
        measure {
            layout.controller.process(changeItems: changeItems)
        }
        layout.controller.commitUpdates()
    }

    func testDeletePerformance() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 10000]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        var changeItems: [ChangeItem] = []
        for i in 0..<10000 {
            changeItems.append(.itemDelete(itemIndexPath: IndexPath(item: i, section: 0)))
        }
        measure {
            layout.controller.process(changeItems: changeItems)
        }
        layout.controller.commitUpdates()
    }

    func testItemUpdatePerformance() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 1000]
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        measure {
            for i in 0..<1000 {
                layout.controller.update(preferredSize: CGSize(width: 300, height: 300), alignment: .center, for: ItemPath(item: i, section: 0), kind: .cell, at: .beforeUpdate)
            }
        }
    }

}
