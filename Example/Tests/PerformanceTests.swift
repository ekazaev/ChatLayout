//
// ChatLayout
// PerformanceTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

@testable import ChatLayout
import Foundation
import XCTest

final class PerformanceTests: XCTestCase {
    func testBinarySearchPerformance() {
        let constant = 1257
        let predicate: (Int) -> ComparisonResult = { integer in
            if integer < constant {
                .orderedAscending
            } else if integer > constant {
                .orderedDescending
            } else {
                .orderedSame
            }
        }
        let values = (0...100000).map { $0 }
        XCTAssertEqual(values.binarySearch(predicate: predicate), constant)
        measure {
            for _ in 0..<100000 {
                _ = values.withUnsafeBufferPointer { $0.binarySearch(predicate: predicate) }
            }
        }
    }

    func testBinarySearchRangePerformance() {
        let constant = 1257
        let predicate: (Int) -> ComparisonResult = { integer in
            if integer < constant {
                .orderedAscending
            } else if integer > constant + 111 {
                .orderedDescending
            } else {
                .orderedSame
            }
        }
        let values = (0...100000).map { $0 }
        XCTAssertEqual(values.binarySearchRange(predicate: predicate), (constant...(constant + 111)).map { $0 })
        measure {
            for _ in 0..<100000 {
                _ = values.withUnsafeBufferPointer { $0.binarySearchRange(predicate: predicate) }
            }
        }
    }

    func testLayoutAttributesForElementsPerformance() {
        let layout = MockCollectionLayout()
        layout.numberOfItemsInSection[0] = 100000
        layout.numberOfItemsInSection[1] = 100000
        layout.shouldPresentHeaderAtSection = [0: false, 1: false]
        layout.shouldPresentFooterAtSection = [0: false, 1: false]
        layout.settings.additionalInsets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        layout.settings.estimatedItemSize = CGSize(width: 300, height: 1)
        layout.settings.interItemSpacing = 0
        layout.settings.interSectionSpacing = 0
        layout.controller.set(layout.getPreparedSections(), at: .beforeUpdate)

        let rect = CGRect(origin: CGPoint(x: 0, y: 99999), size: CGSize(width: 300, height: 2))
        let attributes = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate, ignoreCache: true)
        XCTAssertEqual(attributes.count, 2)
        measure {
            for _ in 0..<10 {
                _ = layout.controller.layoutAttributesForElements(in: rect, state: .beforeUpdate, ignoreCache: true)
            }
        }
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
                layout.controller.update(preferredSize: CGSize(width: 300, height: 300 + i), alignment: .center, interItemSpacing: 0, for: ItemPath(item: i, section: 0), kind: .cell, at: .beforeUpdate)
            }
        }
    }
}
