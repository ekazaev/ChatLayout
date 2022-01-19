//
// ChatLayout
// MockCollectionLayout.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

@testable import ChatLayout
import Foundation
import UIKit

class MockCollectionLayout: ChatLayoutRepresentation, ChatLayoutDelegate {

    var numberOfItemsInSection: [Int: Int] = [0: 100, 1: 100, 2: 100]
    var shouldPresentHeaderAtSection: [Int: Bool] = [0: true, 1: true, 2: true]
    var shouldPresentFooterAtSection: [Int: Bool] = [0: true, 1: true, 2: true]

    // swiftlint:disable weak_delegate
    lazy var delegate: ChatLayoutDelegate? = self
    // swiftlint:enable weak_delegate

    var settings = ChatLayoutSettings(estimatedItemSize: CGSize(width: 300, height: 40), interItemSpacing: 7, interSectionSpacing: 3)
    var viewSize = CGSize(width: 300, height: 400)

    lazy var visibleBounds = CGRect(origin: .zero, size: viewSize)

    var state: ModelState = .beforeUpdate

    lazy var controller = StateController(layoutRepresentation: self)

    /// Represent the rectangle where all the items are aligned.
    public var layoutFrame: CGRect {
        return CGRect(x: adjustedContentInset.left + settings.additionalInsets.left,
                      y: adjustedContentInset.top + settings.additionalInsets.top,
                      width: visibleBounds.width - settings.additionalInsets.left - settings.additionalInsets.right,
                      height: controller.contentHeight(at: state) - settings.additionalInsets.top - settings.additionalInsets.bottom)
    }

    let adjustedContentInset: UIEdgeInsets = .zero

    let keepContentOffsetAtBottomOnBatchUpdates: Bool = true

    func numberOfItems(in section: Int) -> Int {
        return numberOfItemsInSection[section] ?? 0
    }

    func configuration(for element: ItemKind, at itemPath: ItemPath) -> ItemModel.Configuration {
        return .init(alignment: .fullWidth, preferredSize: settings.estimatedItemSize!, calculatedSize: settings.estimatedItemSize!)
    }

    func shouldPresentHeader(at sectionIndex: Int) -> Bool {
        return shouldPresentHeaderAtSection[sectionIndex] ?? true
    }

    func shouldPresentFooter(at sectionIndex: Int) -> Bool {
        return shouldPresentFooterAtSection[sectionIndex] ?? true
    }

    func alignmentForItem(of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment {
        .fullWidth
    }

    func sizeForItem(of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
        return .estimated(settings.estimatedItemSize!)
    }

    func getPreparedSections() -> [SectionModel] {
        var sections: [SectionModel] = []
        for sectionIndex in 0..<numberOfItemsInSection.count {
            let headerIndexPath = ItemPath(item: 0, section: sectionIndex)
            let header = ItemModel(with: configuration(for: .header, at: headerIndexPath))
            let footer = ItemModel(with: configuration(for: .footer, at: headerIndexPath))

            var items: [ItemModel] = []
            for itemIndex in 0..<numberOfItems(in: sectionIndex) {
                let indexPath = ItemPath(item: itemIndex, section: sectionIndex)
                items.append(ItemModel(with: configuration(for: .cell, at: indexPath)))
            }

            var section = SectionModel(header: header, footer: footer, items: items, collectionLayout: self)
            section.assembleLayout()
            sections.append(section)
        }
        return sections
    }

}
