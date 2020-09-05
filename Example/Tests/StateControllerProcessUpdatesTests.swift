//
// ChatLayout
// StateControllerProcessUpdatesTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
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
        let controller = StateController(collectionLayout: layout)
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), layout.settings.estimatedItemSize!.height * (102 * 3) + layout.settings.interItemSpacing * (100 * 3) + layout.settings.interSectionSpacing * 2)

        for i in 0..<layout.numberOfItemsInSection.count {
            let header = controller.item(for: IndexPath(item: 0, section: i), kind: .header, at: .beforeUpdate)
            let footer = controller.item(for: IndexPath(item: 0, section: i), kind: .footer, at: .beforeUpdate)
            XCTAssertNotNil(header)
            XCTAssertNotNil(footer)
            XCTAssertEqual(header?.size, layout.settings.estimatedItemSize)
            XCTAssertEqual(footer?.size, layout.settings.estimatedItemSize)
            XCTAssertEqual(header?.size, controller.itemAttributes(for: IndexPath(item: 0, section: i), kind: .header, at: .beforeUpdate)?.size)
            XCTAssertEqual(footer?.size, controller.itemAttributes(for: IndexPath(item: 0, section: i), kind: .footer, at: .beforeUpdate)?.size)
            for j in 0..<100 {
                let item = controller.item(for: IndexPath(item: j, section: i), kind: .cell, at: .beforeUpdate)
                XCTAssertNotNil(item)
                XCTAssertEqual(item?.size, layout.settings.estimatedItemSize)
                XCTAssertEqual(item?.size, controller.itemAttributes(for: IndexPath(item: j, section: i), kind: .cell, at: .beforeUpdate)?.size)
            }
        }
        XCTAssertNil(controller.item(for: IndexPath(item: 0, section: 5), kind: .header, at: .beforeUpdate))
        XCTAssertNil(controller.item(for: IndexPath(item: 0, section: 5), kind: .footer, at: .beforeUpdate))
    }

    func testItemReload() {
        let layout = MockCollectionLayout()
        let controller = StateController(collectionLayout: layout)
        var updateItems: [UICollectionViewUpdateItem] = []
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        for sectionIndex in 0..<layout.numberOfItemsInSection.count {
            for itemIndex in 0..<layout.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let updateItem = MockUICollectionViewUpdateItem(indexPathBeforeUpdate: indexPath, indexPathAfterUpdate: indexPath, action: .reload)
                updateItems.append(updateItem)
            }
        }

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        controller.process(updateItems: updateItems)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), controller.contentHeight(at: .afterUpdate))
        controller.commitUpdates()

        controller.process(updateItems: [MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 0), indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 0), action: .reload),
                                         MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 1), indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 1), action: .reload)])

        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), controller.contentHeight(at: .afterUpdate))
        controller.commitUpdates()
    }

    func testSectionReload() {
        let layout = MockCollectionLayout()
        let controller = StateController(collectionLayout: layout)
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var updateItems: [UICollectionViewUpdateItem] = []
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 0), indexPathAfterUpdate: nil, action: .reload))
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 1), indexPathAfterUpdate: nil, action: .reload))
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 2), indexPathAfterUpdate: nil, action: .reload))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        layout.numberOfItemsInSection[1] = 50
        controller.process(updateItems: updateItems)

        // Headers
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .afterUpdate), 200)
        XCTAssertEqual(controller.numberOfItems(in: 1, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 1, at: .afterUpdate), 50)
        XCTAssertEqual(controller.numberOfItems(in: 2, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 2, at: .afterUpdate), 100)

        // Frames
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 99, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 100, section: 0), kind: .cell, at: .afterUpdate)?.size, layout.settings.estimatedItemSize)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 49, section: 1), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))

        controller.commitUpdates()
    }

    func testItemInsertion() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 0]
        let controller = StateController(collectionLayout: layout)
        var insertItems: [UICollectionViewUpdateItem] = []
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), layout.settings.estimatedItemSize!.height * (102 + 102 + 2) + layout.settings.interItemSpacing * (100 + 100 + 0) + layout.settings.interSectionSpacing * 2)

        insertItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 100, section: 0), action: .insert))
        insertItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 0, section: 1), action: .insert))
        insertItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 0, section: 2), action: .insert))
        insertItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 1, section: 2), action: .insert))

        controller.process(updateItems: insertItems)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate) + layout.settings.estimatedItemSize!.height * 4.0 + layout.settings.interItemSpacing * 4.0, controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 99, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 99, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 1, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 2, section: 2), kind: .cell, at: .afterUpdate))
        controller.commitUpdates()
    }

    func testSectionInsert() {
        let layout = MockCollectionLayout()
        let controller = StateController(collectionLayout: layout)
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var updateItems: [UICollectionViewUpdateItem] = []
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 1), action: .insert))
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 2), action: .insert))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        layout.numberOfItemsInSection[1] = 50
        layout.numberOfItemsInSection[2] = 300
        layout.numberOfItemsInSection[4] = 100
        controller.process(updateItems: updateItems)

        // Headers
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .afterUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 1, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 1, at: .afterUpdate), 50)
        XCTAssertEqual(controller.numberOfItems(in: 2, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 2, at: .afterUpdate), 300)
        XCTAssertEqual(controller.numberOfItems(in: 3, at: .afterUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 4, at: .afterUpdate), 100)

        // Frames
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 99, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 49, section: 1), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 49, section: 1), kind: .cell, at: .afterUpdate)?.size, layout.settings.estimatedItemSize)

        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 3), kind: .cell, at: .afterUpdate))

        controller.commitUpdates()
    }

    func testItemDeletion() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 1]
        let controller = StateController(collectionLayout: layout)
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var deleteItems: [UICollectionViewUpdateItem] = []
        deleteItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 99, section: 0), indexPathAfterUpdate: nil, action: .delete))
        deleteItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 1), indexPathAfterUpdate: nil, action: .delete))
        deleteItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 2), indexPathAfterUpdate: nil, action: .delete))

        controller.process(updateItems: deleteItems)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate) - layout.settings.estimatedItemSize!.height * 3.0 - layout.settings.interItemSpacing * 3.0, controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 98, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 98, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 1, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 2, section: 2), kind: .cell, at: .afterUpdate))
        controller.commitUpdates()
    }

    func testSectionDelete() {
        let layout = MockCollectionLayout()
        let controller = StateController(collectionLayout: layout)
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var updateItems: [UICollectionViewUpdateItem] = []
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 0), indexPathAfterUpdate: nil, action: .delete))
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 2), indexPathAfterUpdate: nil, action: .delete))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        controller.process(updateItems: updateItems)

        // Headers
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .afterUpdate), 100)
        XCTAssertEqual(controller.numberOfSections(at: .beforeUpdate), 3)
        XCTAssertEqual(controller.numberOfSections(at: .afterUpdate), 1)

        // Frames
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))

        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))

        controller.commitUpdates()
    }

    func testItemMove() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 1]
        let controller = StateController(collectionLayout: layout)
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var moveItems: [UICollectionViewUpdateItem] = []
        moveItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 0), indexPathAfterUpdate: IndexPath(item: 0, section: 2), action: .move))
        moveItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 1), indexPathAfterUpdate: IndexPath(item: 1, section: 1), action: .move))
        moveItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 2), indexPathAfterUpdate: IndexPath(item: 0, section: 0), action: .move))

        controller.process(updateItems: moveItems)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 1, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 1, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 1, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 2, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 2, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.indexPath(by: controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate)!, at: .afterUpdate), IndexPath(item: 0, section: 0))
        XCTAssertEqual(controller.indexPath(by: controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)!, at: .afterUpdate), IndexPath(item: 0, section: 2))
        controller.commitUpdates()
    }

    func testSectionMove() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection[0] = 100
        layout.numberOfItemsInSection[1] = 200
        layout.numberOfItemsInSection[2] = 300
        let controller = StateController(collectionLayout: layout)
        controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        var updateItems: [UICollectionViewUpdateItem] = []
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 0), indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 1), action: .move))
        updateItems.append(MockUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 2), indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 0), action: .move))

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        layout.shouldPresentHeaderAtSection[0] = false
        layout.shouldPresentFooterAtSection[0] = false
        layout.shouldPresentHeaderAtSection[2] = false
        layout.numberOfItemsInSection[0] = 200
        controller.process(updateItems: updateItems)

        // Headers
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .header, at: .afterUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .beforeUpdate))
        XCTAssertNotNil(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .footer, at: .afterUpdate))

        // Items count
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .beforeUpdate), 100)
        XCTAssertEqual(controller.numberOfItems(in: 0, at: .afterUpdate), 300)
        XCTAssertEqual(controller.numberOfItems(in: 1, at: .beforeUpdate), 200)
        XCTAssertEqual(controller.numberOfItems(in: 1, at: .afterUpdate), 200)
        XCTAssertEqual(controller.numberOfItems(in: 2, at: .beforeUpdate), 300)
        XCTAssertEqual(controller.numberOfItems(in: 2, at: .afterUpdate), 100)
        XCTAssertEqual(controller.numberOfSections(at: .beforeUpdate), 3)
        XCTAssertEqual(controller.numberOfSections(at: .afterUpdate), 3)

        // Frames
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .afterUpdate)?.origin, .zero)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size)
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate)?.size, CGSize(width: 300, height: 40))
        XCTAssertEqual(controller.itemFrame(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))

        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .afterUpdate))

        controller.commitUpdates()
    }

}
