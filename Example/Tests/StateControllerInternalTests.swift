//
// ChatLayout
// StateControllerInternalTests.swift
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
final class StateControllerInternalTests: XCTestCase {
    func testUpdatePreferredSizeUpdatesFollowingItemOffsets() throws {
        let layout = MockCollectionLayout()
        layout.setSections([4])
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        layout.controller.update(
            preferredSize: CGSize(width: 300, height: 300),
            alignment: .center,
            interItemSpacing: 0,
            pinningType: nil,
            for: ItemPath(item: 0, section: 0),
            at: .beforeUpdate
        )

        let updatedFrame = try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 0, section: 0), at: .beforeUpdate))
        let followingFrame = try XCTUnwrap(layout.controller.itemFrame(for: ItemPath(item: 1, section: 0), at: .beforeUpdate))

        XCTAssertEqual(updatedFrame.size, CGSize(width: 300, height: 300))
        XCTAssertEqual(followingFrame.origin.y, 307)
        XCTAssertEqual(followingFrame.size, CGSize(width: 300, height: 40))
    }

    func testUpdatePreferredAlignmentAdjustsFrames() throws {
        let layout = MockCollectionLayout()
        layout.setSections([5])
        layout.settings.additionalInsets = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 7)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        layout.controller.update(
            preferredSize: CGSize(width: 100, height: 100),
            alignment: .leading,
            interItemSpacing: 0,
            pinningType: nil,
            for: ItemPath(item: 0, section: 0),
            at: .beforeUpdate
        )
        layout.controller.update(
            preferredSize: CGSize(width: 100, height: 100),
            alignment: .trailing,
            interItemSpacing: 0,
            pinningType: nil,
            for: ItemPath(item: 1, section: 0),
            at: .beforeUpdate
        )
        layout.controller.update(
            preferredSize: CGSize(width: 100, height: 100),
            alignment: .center,
            interItemSpacing: 0,
            pinningType: nil,
            for: ItemPath(item: 2, section: 0),
            at: .beforeUpdate
        )
        layout.controller.update(
            preferredSize: CGSize(width: 100, height: 100),
            alignment: .fullWidth,
            interItemSpacing: 0,
            pinningType: nil,
            for: ItemPath(item: 3, section: 0),
            at: .beforeUpdate
        )

        let leadingAttributes = try XCTUnwrap(layout.controller.itemAttributes(for: ItemPath(item: 0, section: 0), at: .beforeUpdate))
        let trailingAttributes = try XCTUnwrap(layout.controller.itemAttributes(for: ItemPath(item: 1, section: 0), at: .beforeUpdate))
        let centeredAttributes = try XCTUnwrap(layout.controller.itemAttributes(for: ItemPath(item: 2, section: 0), at: .beforeUpdate))
        let fullWidthAttributes = try XCTUnwrap(layout.controller.itemAttributes(for: ItemPath(item: 3, section: 0), at: .beforeUpdate))
        let untouchedAttributes = try XCTUnwrap(layout.controller.itemAttributes(for: ItemPath(item: 4, section: 0), at: .beforeUpdate))

        XCTAssertEqual(leadingAttributes.alignment, .leading)
        XCTAssertEqual(leadingAttributes.frame.origin.x, 13)

        XCTAssertEqual(trailingAttributes.alignment, .trailing)
        XCTAssertEqual(trailingAttributes.frame.origin.x, 193)

        XCTAssertEqual(centeredAttributes.alignment, .center)
        XCTAssertEqual(centeredAttributes.frame.origin.x, 103)

        XCTAssertEqual(fullWidthAttributes.alignment, .fullWidth)
        XCTAssertEqual(fullWidthAttributes.frame.origin.x, 13)
        XCTAssertEqual(fullWidthAttributes.frame.width, 280)

        XCTAssertEqual(untouchedAttributes.alignment, .fullWidth)
        XCTAssertEqual(untouchedAttributes.frame.origin.x, 13)
        XCTAssertEqual(untouchedAttributes.frame.width, 280)
    }

    func testItemAndSectionIdentifiersRoundTrip() throws {
        let layout = MockCollectionLayout()
        layout.setSections([2, 1])
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        let section0Identifier = try XCTUnwrap(layout.controller.sectionIdentifier(for: 0, at: .beforeUpdate))
        let section1Identifier = try XCTUnwrap(layout.controller.sectionIdentifier(for: 1, at: .beforeUpdate))
        let itemIdentifier = try XCTUnwrap(layout.controller.itemIdentifier(for: ItemPath(item: 1, section: 0), at: .beforeUpdate))

        XCTAssertEqual(layout.controller.sectionIndex(for: section0Identifier, at: .beforeUpdate), 0)
        XCTAssertEqual(layout.controller.sectionIndex(for: section1Identifier, at: .beforeUpdate), 1)
        XCTAssertEqual(layout.controller.itemPath(by: itemIdentifier, at: .beforeUpdate), ItemPath(item: 1, section: 0))
        XCTAssertNil(layout.controller.itemIdentifier(for: ItemPath(item: 2, section: 1), at: .beforeUpdate))
        XCTAssertNil(layout.controller.sectionIdentifier(for: 2, at: .beforeUpdate))
    }

    func testLayoutAttributesInRectCaching() throws {
        let layout = MockCollectionLayout()
        layout.setSections([5, 5])
        layout.settings.additionalInsets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        let rect = CGRect(origin: .zero, size: CGSize(width: 300, height: 400))
        let attributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        XCTAssertEqual(attributes.count, 9)
        XCTAssertTrue(attributes.allSatisfy { $0.frame.intersects(rect) })

        let cachedAttributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        XCTAssertEqual(cachedAttributes.count, attributes.count)
        for index in attributes.indices {
            XCTAssertTrue(cachedAttributes[index] === attributes[index])
        }

        layout.controller.resetCachedAttributes()

        let cachedObjectsAttributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        XCTAssertEqual(cachedObjectsAttributes.count, attributes.count)
        for index in attributes.indices {
            XCTAssertTrue(cachedObjectsAttributes[index] === attributes[index])
        }

        layout.controller.resetCachedAttributes()
        layout.controller.resetCachedAttributeObjects()

        let rebuiltAttributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate)
        XCTAssertEqual(rebuiltAttributes.count, attributes.count)
        for index in attributes.indices {
            XCTAssertTrue(rebuiltAttributes[index].isEqual(attributes[index]))
            XCTAssertFalse(rebuiltAttributes[index] === attributes[index])
        }
    }

    func testContentSizeIncludesAdditionalInsets() {
        let layout = MockCollectionLayout()
        layout.setSections([5, 5, 5])
        layout.settings.additionalInsets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        let expectedHeight: CGFloat = 10.0 + 30.0 + 15.0 * 40.0 + 12.0 * 7.0 + 2.0 * 3.0
        let contentSize = layout.controller.contentSize(for: .beforeUpdate)

        XCTAssertEqual(layout.controller.contentHeight(at: .beforeUpdate), expectedHeight)
        XCTAssertEqual(contentSize.width, layout.viewSize.width - 0.0001, accuracy: 0.0001)
        XCTAssertEqual(contentSize.height, expectedHeight)
    }
}
