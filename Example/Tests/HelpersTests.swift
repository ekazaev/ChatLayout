//
// ChatLayout
// HelpersTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

@testable import ChatLayout
import Foundation
import XCTest

@MainActor
final class HelpersTests: XCTestCase {
    func testItemKindInit() {
        let header = ItemKind(UICollectionView.elementKindSectionHeader)
        XCTAssertTrue(header == ItemKind.header)

        let footer = ItemKind(UICollectionView.elementKindSectionFooter)
        XCTAssertTrue(footer == ItemKind.footer)
    }

    func testItemKindSupplementaryType() {
        let header = ItemKind.header
        XCTAssertTrue(header.isSupplementaryItem)

        let footer = ItemKind.footer
        XCTAssertTrue(footer.isSupplementaryItem)

        let cell = ItemKind.cell
        XCTAssertFalse(cell.isSupplementaryItem)
    }

    func testSupplementaryElementStringType() {
        let header = ItemKind(UICollectionView.elementKindSectionHeader)
        XCTAssertTrue(header.supplementaryElementStringType == UICollectionView.elementKindSectionHeader)

        let footer = ItemKind(UICollectionView.elementKindSectionFooter)
        XCTAssertTrue(footer.supplementaryElementStringType == UICollectionView.elementKindSectionFooter)
    }

    func testBinarySearch() {
        let predicate: (Int) -> ComparisonResult = { integer in
            if integer < 100 {
                .orderedAscending
            } else if integer > 100 {
                .orderedDescending
            } else {
                .orderedSame
            }
        }
        XCTAssertEqual([Int]().binarySearch(predicate), nil)
        XCTAssertEqual((0...1000).map { $0 }.binarySearch(predicate), 100)
        XCTAssertEqual((100...200).map { $0 }.binarySearch(predicate), 0)
        XCTAssertEqual((0...0).map { $0 }.binarySearch(predicate), nil)
        XCTAssertEqual((100...100).map { $0 }.binarySearch(predicate), 0)
        XCTAssertEqual((200...200).map { $0 }.binarySearch(predicate), nil)
        XCTAssertEqual((99...100).map { $0 }.binarySearch(predicate), 1)
        XCTAssertEqual((200...201).map { $0 }.binarySearch(predicate), nil)
        XCTAssertEqual((0...150).map { $0 }.binarySearch(predicate), 100)
        XCTAssertEqual((150...170).map { $0 }.binarySearch(predicate), nil)
    }

    func testBinarySearchWithCGRect() {
        let visibleRect = CGRect(origin: .init(x: 0, y: 100), size: .init(width: 100, height: 100))
        let predicate: (CGRect) -> ComparisonResult = { frame in
            if frame.intersects(visibleRect) {
                return .orderedSame
            } else if frame.minY >= visibleRect.maxY {
                return .orderedDescending
            } else if frame.maxX <= visibleRect.minY {
                return .orderedAscending
            }
            XCTFail("Should not get here")
            return .orderedSame
        }
        XCTAssertEqual([CGRect]().binarySearch(predicate), nil)
        XCTAssertEqual((0...5).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearch(predicate), 3)
        XCTAssertEqual((-1...1).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearch(predicate), nil)
        XCTAssertEqual((1...1).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearch(predicate), nil)
        XCTAssertEqual((4...7).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearch(predicate), nil)
        XCTAssertEqual((4...4).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearch(predicate), nil)

        XCTAssertEqual([CGRect]().binarySearchRange(predicate), [])
        XCTAssertEqual((0...5).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearchRange(predicate).count, 2)
        XCTAssertEqual((-1...1).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearchRange(predicate).count, 0)
        XCTAssertEqual((1...1).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearchRange(predicate).count, 0)
        XCTAssertEqual((4...7).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearchRange(predicate).count, 0)
        XCTAssertEqual((4...4).map { CGRect(origin: .init(x: 0, y: $0 * 50), size: .init(width: 100, height: 50)) }.binarySearchRange(predicate).count, 0)
    }

    func testSearchInRange() {
        let predicate: (Int) -> ComparisonResult = { integer in
            if integer < 100 {
                .orderedAscending
            } else if integer > 200 {
                .orderedDescending
            } else {
                .orderedSame
            }
        }
        XCTAssertEqual([Int]().binarySearchRange(predicate), [])
        XCTAssertEqual((0...1000).map { $0 }.binarySearchRange(predicate), (100...200).map { $0 })
        XCTAssertEqual((100...200).map { $0 }.binarySearchRange(predicate), (100...200).map { $0 })
        XCTAssertEqual((0...0).map { $0 }.binarySearchRange(predicate), [])
        XCTAssertEqual((100...100).map { $0 }.binarySearchRange(predicate), [100])
        XCTAssertEqual((200...200).map { $0 }.binarySearchRange(predicate), [200])
        XCTAssertEqual((99...100).map { $0 }.binarySearchRange(predicate), [100])
        XCTAssertEqual((200...201).map { $0 }.binarySearchRange(predicate), [200])
        XCTAssertEqual((0...150).map { $0 }.binarySearchRange(predicate), (100...150).map { $0 })
        XCTAssertEqual((150...200).map { $0 }.binarySearchRange(predicate), (150...200).map { $0 })
        XCTAssertEqual((150...250).map { $0 }.binarySearchRange(predicate), (150...200).map { $0 })
        XCTAssertEqual((150...170).map { $0 }.binarySearchRange(predicate), (150...170).map { $0 })
    }

    func testItemSizeHasher() {
        let size = CGSize(width: 100, height: 100)
        var dictionary = [ItemSize: Int]()
        dictionary[.auto] = 0
        dictionary[.estimated(.zero)] = 1
        dictionary[.estimated(size)] = 2
        dictionary[.exact(.zero)] = 3
        dictionary[.exact(size)] = 4

        XCTAssertEqual(dictionary[.auto], 0)
        XCTAssertEqual(dictionary[.estimated(.zero)], 1)
        XCTAssertEqual(dictionary[.estimated(size)], 2)
        XCTAssertEqual(dictionary[.exact(.zero)], 3)
        XCTAssertEqual(dictionary[.exact(size)], 4)
    }
}
