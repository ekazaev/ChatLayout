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

        lazy var delegate: ChatLayoutDelegate? = self
        var settings: ChatLayoutSettings = ChatLayoutSettings(estimatedItemSize: CGSize(width: 300, height: 40), interItemSpacing: 7, interSectionSpacing: 3)
        var viewSize: CGSize = CGSize(width: 300, height: 400)
        lazy var visibleBounds: CGRect = CGRect(origin: .zero, size: viewSize)
        lazy var layoutFrame: CGRect = visibleBounds
        let adjustedContentInset: UIEdgeInsets = .zero
        let keepContentOffestAtBottomOnBatchUpdates: Bool = true

        func numberOfItems(inSection section: Int) -> Int {
            return 100
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
        for sectionIndex in 0..<5 {
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

        XCTAssertEqual(controller.contentHeight(at: .beforeUpdate), 23947.0)
        for i in 0..<5 {
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

        for sectionIndex in 0..<2 {
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

}
