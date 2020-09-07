//
// ChatLayout
// StateControllerInternalTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

@testable import ChatLayout
import XCTest

class StateControllerInternalTests: XCTestCase {

    func testUpdatePreferredSize() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 300, height: 100), for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 300, height: 300), for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 300, height: 100), for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)
        XCTAssertEqual(layout.controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.size, CGSize(width: 300, height: 100))
        XCTAssertEqual(layout.controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)?.size, CGSize(width: 300, height: 100))
        XCTAssertEqual(layout.controller.itemFrame(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 300))
        XCTAssertEqual(layout.controller.itemFrame(for: IndexPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.size, CGSize(width: 300, height: 40))
    }

    func testUpdatePreferredAlignment() {
        let layout = MockCollectionLayout()
        layout.settings.additionalInsets = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 7)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 300), for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)
        layout.controller.update(preferredSize: CGSize(width: 100, height: 100), for: IndexPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)

        layout.controller.update(alignment: .leading, for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)
        layout.controller.update(alignment: .trailing, for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)
        layout.controller.update(alignment: .center, for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)
        layout.controller.update(alignment: .full, for: IndexPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)

        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.alignment, .trailing)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)?.alignment, .leading)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.alignment, .center)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.alignment, .full)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 2, section: 0), kind: .cell, at: .beforeUpdate)?.alignment, .full)

        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate)?.frame.origin.x, 300 - 100 - layout.settings.additionalInsets.right)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate)?.frame.origin.x, layout.settings.additionalInsets.left)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate)?.frame.origin.x, layout.settings.additionalInsets.left + (300 - layout.settings.additionalInsets.right - layout.settings.additionalInsets.left) / 2 - 100 / 2)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.frame.origin.x, layout.settings.additionalInsets.left)
        XCTAssertEqual(layout.controller.itemAttributes(for: IndexPath(item: 1, section: 0), kind: .cell, at: .beforeUpdate)?.frame.width, 300 - layout.settings.additionalInsets.left - layout.settings.additionalInsets.right)
    }

    func testItemIdentifierAtIndexPath() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        XCTAssertEqual(layout.controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .cell, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].items[0].id)
        XCTAssertEqual(layout.controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .header, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].header?.id)
        XCTAssertEqual(layout.controller.itemIdentifier(for: IndexPath(item: 0, section: 0), kind: .footer, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].footer?.id)
    }

    func testSectionIdentifierAtIndexPath() {
        let layout = MockCollectionLayout()
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)
        XCTAssertEqual(layout.controller.sectionIdentifier(for: 0, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[0].id)
        XCTAssertEqual(layout.controller.sectionIdentifier(for: 1, at: .beforeUpdate), layout.controller.storage[.beforeUpdate]?.sections[1].id)
    }

}
