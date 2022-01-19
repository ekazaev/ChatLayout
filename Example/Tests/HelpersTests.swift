//
// ChatLayout
// HelpersTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

@testable import ChatLayout
import Foundation
import XCTest

final class HelpersTests: XCTestCase {

    func testCGRectEqualRounded() {
        let origin = CGPoint(x: CGFloat.random(in: 0...100), y: CGFloat.random(in: 0...100))
        let size = CGSize(width: CGFloat.random(in: 1...100), height: CGFloat.random(in: 1...100))
        let rect = CGRect(origin: origin, size: size)

        XCTAssertTrue(rect.equalRounded(to: CGRect(origin: origin, size: size)))
        XCTAssertTrue(rect.equalRounded(to: CGRect(origin: origin, size: size).offsetBy(dx: 0.1, dy: 0.3)))
        XCTAssertTrue(rect.equalRounded(to: CGRect(origin: origin, size: size).offsetBy(dx: 1, dy: 1)))
        XCTAssertTrue(rect.equalRounded(to: CGRect(origin: origin, size: size).offsetBy(dx: 0.99999999, dy: 0.9999999)))
        XCTAssertTrue(rect.equalRounded(to: CGRect(origin: origin, size: CGSize(width: size.width + 0.0001, height: size.height + 0.99999))))
        XCTAssertFalse(rect.equalRounded(to: CGRect(origin: origin, size: size).offsetBy(dx: 1.1, dy: 0.3)))
        XCTAssertFalse(rect.equalRounded(to: CGRect(origin: origin, size: size).offsetBy(dx: 1.1, dy: 1.3)))
        XCTAssertFalse(rect.equalRounded(to: CGRect(origin: origin, size: size).offsetBy(dx: 0.1, dy: 1.3)))
        XCTAssertFalse(rect.equalRounded(to: CGRect(origin: origin, size: CGSize(width: size.width + 1.0001, height: size.height))))
    }

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

    func testSearchInRange() {
        let predicate: (Int) -> ComparisonResult = { integer in
            if integer < 100 {
                return .orderedAscending
            } else if integer > 200 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
        XCTAssertEqual((0...1000).map { $0 }.binarySearchRange(predicate: predicate), (100...200).map { $0 })
        XCTAssertEqual((100...200).map { $0 }.binarySearchRange(predicate: predicate), (100...200).map { $0 })
        XCTAssertEqual((0...0).map { $0 }.binarySearchRange(predicate: predicate), [])
        XCTAssertEqual((0...150).map { $0 }.binarySearchRange(predicate: predicate), (100...150).map { $0 })
        XCTAssertEqual((150...200).map { $0 }.binarySearchRange(predicate: predicate), (150...200).map { $0 })
        XCTAssertEqual((150...170).map { $0 }.binarySearchRange(predicate: predicate), (150...170).map { $0 })
    }

}
