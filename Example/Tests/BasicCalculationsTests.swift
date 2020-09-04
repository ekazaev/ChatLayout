//
// ChatLayout
// Tests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import XCTest
@testable import ChatLayout

class BasicCalculationsTests: XCTestCase {

    class TestCollectionLayout: ChatLayoutRepresentation, ChatLayoutDelegate {

        var numberOfItemsInSection: [Int: Int] = [0: 100, 1: 100, 2: 100]
        lazy var delegate: ChatLayoutDelegate? = self
        var settings: ChatLayoutSettings = ChatLayoutSettings(estimatedItemSize: CGSize(width: 300, height: 40), interItemSpacing: 7, interSectionSpacing: 3)
        var viewSize: CGSize = CGSize(width: 300, height: 400)
        lazy var visibleBounds: CGRect = CGRect(origin: .zero, size: viewSize)
        lazy var layoutFrame: CGRect = visibleBounds
        let adjustedContentInset: UIEdgeInsets = .zero
        let keepContentOffsetAtBottomOnBatchUpdates: Bool = true

        func numberOfItems(inSection section: Int) -> Int {
            return numberOfItemsInSection[section] ?? 0
        }

        func configuration(for element: ItemKind, at indexPath: IndexPath) -> ItemModel.Configuration {
            return .init(alignment: .full, preferredSize: settings.estimatedItemSize!, calculatedSize: settings.estimatedItemSize!)
        }

        func shouldPresentHeader(at sectionIndex: Int) -> Bool {
            return true
        }

        func shouldPresentFooter(at sectionIndex: Int) -> Bool {
            return true
        }

        func alignmentForItem(of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment {
            .full
        }

        func sizeForItem(of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
            return .estimated(settings.estimatedItemSize!)
        }

    }

    class TestUICollectionViewUpdateItem: UICollectionViewUpdateItem {

        var _indexPathBeforeUpdate: IndexPath?
        var _indexPathAfterUpdate: IndexPath?
        var _updateAction: Action

        init(indexPathBeforeUpdate: IndexPath?, indexPathAfterUpdate: IndexPath?, action: Action) {
            self._indexPathBeforeUpdate = indexPathBeforeUpdate
            self._indexPathAfterUpdate = indexPathAfterUpdate
            self._updateAction = action
            super.init()
        }

        override var indexPathBeforeUpdate: IndexPath? {
            return _indexPathBeforeUpdate
        }

        override var indexPathAfterUpdate: IndexPath? {
            return _indexPathAfterUpdate
        }

        override var updateAction: Action {
            return _updateAction
        }

    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHeight() {
        let layout = TestCollectionLayout()
        let controller = StateController(collectionLayout: layout)
        var sections: [SectionModel] = []
        for sectionIndex in 0..<layout.numberOfItemsInSection.count {
            let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
            let header = ItemModel(with: layout.configuration(for: .header, at: headerIndexPath))
            let footer = ItemModel(with: layout.configuration(for: .footer, at: headerIndexPath))

            var items: [ItemModel] = []
            for itemIndex in 0..<layout.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                items.append(ItemModel(with: layout.configuration(for: .cell, at: indexPath)))
            }

            var section = SectionModel(header: header, footer: footer, items: items, collectionLayout: layout)
            section.assembleLayout()
            sections.append(section)
        }
        controller.set(sections, at: .beforeUpdate)

        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), 14367)
        for i in 0..<layout.numberOfItemsInSection.count {
            let header = controller.item(for: IndexPath(item: 0, section: i), kind: .header, at: .beforeUpdate)
            let footer = controller.item(for: IndexPath(item: 0, section: i), kind: .footer, at: .beforeUpdate)
            XCTAssertNotNil(header)
            XCTAssertNotNil(footer)
            XCTAssertEqual(header?.size, CGSize(width: 300, height: 40))
            XCTAssertEqual(footer?.size, CGSize(width: 300, height: 40))
            XCTAssertEqual(header?.size, controller.itemAttributes(for: IndexPath(item: 0, section: i), kind: .header, at: .beforeUpdate)?.size)
            XCTAssertEqual(footer?.size, controller.itemAttributes(for: IndexPath(item: 0, section: i), kind: .footer, at: .beforeUpdate)?.size)
            for j in 0..<100 {
                let item = controller.item(for: IndexPath(item: j, section: i), kind: .cell, at: .beforeUpdate)
                XCTAssertNotNil(item)
                XCTAssertEqual(item?.size, CGSize(width: 300, height: 40))
                XCTAssertEqual(item?.size, controller.itemAttributes(for: IndexPath(item: j, section: i), kind: .cell, at: .beforeUpdate)?.size)
            }
        }
        XCTAssertNil(controller.item(for: IndexPath(item: 0, section: 5), kind: .header, at: .beforeUpdate))
        XCTAssertNil(controller.item(for: IndexPath(item: 0, section: 5), kind: .footer, at: .beforeUpdate))
    }

    func testFullReload() {
        let layout = TestCollectionLayout()
        let controller = StateController(collectionLayout: layout)
        var sections: [SectionModel] = []
        var updateItems: [UICollectionViewUpdateItem] = []

        for sectionIndex in 0..<layout.numberOfItemsInSection.count {
            let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
            let header = ItemModel(with: layout.configuration(for: .header, at: headerIndexPath))
            let footer = ItemModel(with: layout.configuration(for: .footer, at: headerIndexPath))

            var items: [ItemModel] = []
            for itemIndex in 0..<layout.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                items.append(ItemModel(with: layout.configuration(for: .cell, at: indexPath)))

                let updateItem = TestUICollectionViewUpdateItem(indexPathBeforeUpdate: indexPath, indexPathAfterUpdate: indexPath, action: .reload)
                updateItems.append(updateItem)
            }

            var section = SectionModel(header: header, footer: footer, items: items, collectionLayout: layout)
            section.assembleLayout()
            sections.append(section)
        }
        controller.set(sections, at: .beforeUpdate)

        layout.settings.estimatedItemSize = .init(width: 300, height: 50)
        controller.process(updateItems: updateItems)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), controller.contentHeight(at: .afterUpdate))
        controller.commitUpdates()

        controller.process(updateItems: [TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 0), indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 0), action: .reload),
                                         TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: NSNotFound, section: 1), indexPathAfterUpdate: IndexPath(item: NSNotFound, section: 1), action: .reload)])
        
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), controller.contentHeight(at: .afterUpdate))
        controller.commitUpdates()
    }

    func testItemInsertion() {
        let layout = TestCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 0]
        let controller = StateController(collectionLayout: layout)
        var sections: [SectionModel] = []
        var insertItems: [UICollectionViewUpdateItem] = []

        for sectionIndex in 0..<layout.numberOfItemsInSection.count {
            let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
            let header = ItemModel(with: layout.configuration(for: .header, at: headerIndexPath))
            let footer = ItemModel(with: layout.configuration(for: .footer, at: headerIndexPath))

            var items: [ItemModel] = []
            for itemIndex in 0..<layout.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                items.append(ItemModel(with: layout.configuration(for: .cell, at: indexPath)))

            }

            var section = SectionModel(header: header, footer: footer, items: items, collectionLayout: layout)
            section.assembleLayout()
            sections.append(section)
        }
        controller.set(sections, at: .beforeUpdate)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), layout.settings.estimatedItemSize!.height * (102 + 102 + 2) + layout.settings.interItemSpacing * (101 + 101 + 1) + layout.settings.interSectionSpacing * 2)

        insertItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 100, section: 0), action: .insert))
        insertItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 0, section: 1), action: .insert))
        insertItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 0, section: 2), action: .insert))
        insertItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: nil, indexPathAfterUpdate: IndexPath(item: 1, section: 2), action: .insert))

        controller.process(updateItems: insertItems)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate) + layout.settings.estimatedItemSize!.height * 4.0 + layout.settings.interItemSpacing * 4.0, controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 99, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 99, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 1, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 0, section: 2), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 2, section: 2), kind: .cell, at: .afterUpdate))
        controller.commitUpdates()
    }

    func testItemDeletion() {
        let layout = TestCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 1]
        let controller = StateController(collectionLayout: layout)
        var sections: [SectionModel] = []

        for sectionIndex in 0..<layout.numberOfItemsInSection.count {
            let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
            let header = ItemModel(with: layout.configuration(for: .header, at: headerIndexPath))
            let footer = ItemModel(with: layout.configuration(for: .footer, at: headerIndexPath))

            var items: [ItemModel] = []
            for itemIndex in 0..<layout.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                items.append(ItemModel(with: layout.configuration(for: .cell, at: indexPath)))

            }

            var section = SectionModel(header: header, footer: footer, items: items, collectionLayout: layout)
            section.assembleLayout()
            sections.append(section)
        }
        controller.set(sections, at: .beforeUpdate)

        var deleteItems: [UICollectionViewUpdateItem] = []
        deleteItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 99, section: 0), indexPathAfterUpdate: nil, action: .delete))
        deleteItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 1), indexPathAfterUpdate: nil, action: .delete))
        deleteItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 2), indexPathAfterUpdate: nil, action: .delete))

        controller.process(updateItems: deleteItems)
        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate) - layout.settings.estimatedItemSize!.height * 3.0 - layout.settings.interItemSpacing * 3.0, controller.contentHeight(at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 98, section: 0), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 98, section: 0), kind: .cell, at: .afterUpdate))
        XCTAssertEqual(controller.itemIdentifier(for: IndexPath(item: 1, section: 1), kind: .cell, at: .beforeUpdate), controller.itemIdentifier(for: IndexPath(item: 0, section: 1), kind: .cell, at: .afterUpdate))
        XCTAssertNil(controller.itemIdentifier(for: IndexPath(item: 2, section: 2), kind: .cell, at: .afterUpdate))
        controller.commitUpdates()
    }

    func testItemMove() {
        let layout = TestCollectionLayout()
        layout.numberOfItemsInSection = [0: 100, 1: 100, 2: 1]
        let controller = StateController(collectionLayout: layout)
        var sections: [SectionModel] = []

        for sectionIndex in 0..<layout.numberOfItemsInSection.count {
            let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
            let header = ItemModel(with: layout.configuration(for: .header, at: headerIndexPath))
            let footer = ItemModel(with: layout.configuration(for: .footer, at: headerIndexPath))

            var items: [ItemModel] = []
            for itemIndex in 0..<layout.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                items.append(ItemModel(with: layout.configuration(for: .cell, at: indexPath)))

            }

            var section = SectionModel(header: header, footer: footer, items: items, collectionLayout: layout)
            section.assembleLayout()
            sections.append(section)
        }
        controller.set(sections, at: .beforeUpdate)

        var moveItems: [UICollectionViewUpdateItem] = []
        moveItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 0), indexPathAfterUpdate: IndexPath(item: 0, section: 2), action: .move))
        moveItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 1), indexPathAfterUpdate: IndexPath(item: 1, section: 1), action: .move))
        moveItems.append(TestUICollectionViewUpdateItem(indexPathBeforeUpdate: IndexPath(item: 0, section: 2), indexPathAfterUpdate: IndexPath(item: 0, section: 0), action: .move))

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

}
