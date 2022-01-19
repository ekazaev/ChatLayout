//
// ChatLayout
// StateControllerInternalTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

@testable import ChatLayout
import XCTest

class StateControllerInternalTests: XCTestCase {

    func testUpdatePreferredSize() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 300, height: 100), alignment: .center, for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 300, height: 300), alignment: .center, for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 300, height: 100), alignment: .center, for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.size, CGSize(width: 300, height: 100))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)?.size, CGSize(width: 300, height: 100))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 300))
        XCTAssertEqual(layout.controller.itemFrame(for: ItemPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))
    }

    func testUpdatePreferredAlignment() {
        let layout = MockCollectionLayout()
        layout.settings.additionalInsets = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 7)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), alignment: .center, for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 300), alignment: .center, for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), alignment: .center, for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), alignment: .center, for: ItemPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)

        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), alignment: .leading, for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), alignment: .trailing, for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), alignment: .center, for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), alignment: .fullWidth, for: ItemPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)

        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.alignment, .trailing)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)?.alignment, .leading)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.alignment, .center)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.alignment, .fullWidth)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 2, section: 0), kind: .cell, at: .beforeUpdate)?.alignment, .fullWidth)

        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.frame.origin.x, 300 - 100 - layout.settings.additionalInsets.right)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)?.frame.origin.x, layout.settings.additionalInsets.left)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.frame.origin.x, layout.settings.additionalInsets.left + (300 - layout.settings.additionalInsets.right - layout.settings.additionalInsets.left) / 2 - 100 / 2)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.frame.origin.x, layout.settings.additionalInsets.left)
        XCTAssertEqual(layout.controller.itemAttributes(for: ItemPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.frame.width, 300 - layout.settings.additionalInsets.left - layout.settings.additionalInsets.right)
    }

    func testItemIdentifierAtIndexPath() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].items[0].id)
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .header, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].header?.id)
        XCTAssertEqual(layout.controller.itemIdentifier(for: ItemPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].footer?.id)
    }

    func testSectionIdentifierAtIndexPath() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        XCTAssertEqual(layout.controller.sectionIdentifier(for: 0, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].id)
        XCTAssertEqual(layout.controller.sectionIdentifier(for: 1, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[1].id)
    }

    func testLayoutAttributesInRect() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection[0] = 5
        layout.numberOfItemsInSection[1] = 5
        layout.settings.additionalInsets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        let rect = CGRect(origin: .zero, size: CGSize(width: 300, height: 400))
        let attributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        XCTAssertEqual(attributes.count, 9)
        attributes.forEach { attributes in
            XCTAssertTrue(attributes.frame.intersects(rect))
        }
    }

    func testLayoutAttributesInRectCaching() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection[0] = 5
        layout.numberOfItemsInSection[1] = 5
        layout.settings.additionalInsets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        let rect = CGRect(origin: .zero, size: CGSize(width: 300, height: 400))
        let attributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        let cachedAttributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        XCTAssertEqual(cachedAttributes.count, attributes.count)
        if cachedAttributes.count == attributes.count {
            cachedAttributes.enumerated().forEach { index, cachedAttributes in
                XCTAssertTrue(cachedAttributes === attributes[index])
            }
        }

        layout.controller.resetCachedAttributes()

        let cachedInObjectsAttributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        XCTAssertEqual(cachedInObjectsAttributes.count, attributes.count)
        XCTAssertEqual(cachedInObjectsAttributes.count, cachedAttributes.count)
        if cachedInObjectsAttributes.count == attributes.count {
            cachedInObjectsAttributes.enumerated().forEach { index, nonCachedAttributes in
                XCTAssertTrue(nonCachedAttributes == attributes[index])
                XCTAssertTrue(nonCachedAttributes == cachedAttributes[index])
            }
        }

        layout.controller.resetCachedAttributes()
        layout.controller.resetCachedAttributeObjects()

        let notCachedAttributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)

        if notCachedAttributes.count == attributes.count {
            notCachedAttributes.enumerated().forEach { index, nonCachedAttributes in
                XCTAssertTrue(nonCachedAttributes !== attributes[index])
                XCTAssertTrue(nonCachedAttributes !== cachedAttributes[index])
            }
        }
    }

    func testContentSize() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection[0] = 5
        layout.numberOfItemsInSection[1] = 5
        layout.numberOfItemsInSection[2] = 5
        layout.settings.additionalInsets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        let estimatedContentHeight = layout.settings.additionalInsets.top + layout.settings.additionalInsets.bottom + layout.settings.estimatedItemSize!.height * (7 * 3) + layout.settings.interItemSpacing * (5 * 3) + layout.settings.interSectionSpacing * 2
        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), estimatedContentHeight)
        XCTAssertEqual(layout.controller.contentSize(for: .beforeUpdate), CGSize(width: layout.viewSize.width - 0.0001, height: estimatedContentHeight))
    }

}
