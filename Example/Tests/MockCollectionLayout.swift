//
// ChatLayout
// MockCollectionLayout.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

@testable import ChatLayout
import Foundation
import UIKit

class MockCollectionLayout: ChatLayoutRepresentation, ChatLayoutDelegate {
    var numberOfItemsInSection: [Int: Int] = [0: 100, 1: 100, 2: 100]
    var pinningTypeAtIndexPath: [IndexPath: ChatItemPinningType] = [:]
    var preferredSizeAtIndexPath: [IndexPath: CGSize] = [:]
    var calculatedSizeAtIndexPath: [IndexPath: CGSize] = [:]
    var alignmentAtIndexPath: [IndexPath: ChatItemAlignment] = [:]
    var interItemSpacingAtIndexPath: [IndexPath: CGFloat] = [:]
    var interSectionSpacingAtSection: [Int: CGFloat] = [:]

    // swiftlint:disable weak_delegate
    lazy var delegate: ChatLayoutDelegate? = self
    // swiftlint:enable weak_delegate

    var settings = ChatLayoutSettings(estimatedItemSize: CGSize(width: 300, height: 40), interItemSpacing: 7, interSectionSpacing: 3)
    var viewSize = CGSize(width: 300, height: 400)

    lazy var visibleBounds = CGRect(origin: .zero, size: viewSize)

    var state: ModelState = .beforeUpdate

    lazy var controller = StateController(layoutRepresentation: self)

    /// Represent the rectangle where all the items are aligned.
    var layoutFrame: CGRect {
        CGRect(
            x: adjustedContentInset.left + settings.additionalInsets.left,
            y: adjustedContentInset.top + settings.additionalInsets.top,
            width: visibleBounds.width - settings.additionalInsets.left - settings.additionalInsets.right,
            height: controller.contentHeight(at: state) - settings.additionalInsets.top - settings.additionalInsets.bottom
        )
    }

    let adjustedContentInset: UIEdgeInsets = .zero

    let keepContentOffsetAtBottomOnBatchUpdates: Bool = true

    let keepContentAtBottomOfVisibleArea: Bool = false

    let processOnlyVisibleItemsOnAnimatedBatchUpdates: Bool = true

    func setSections(_ counts: [Int]) {
        numberOfItemsInSection = Dictionary(uniqueKeysWithValues: counts.enumerated().map { ($0.offset, $0.element) })
    }

    func numberOfItems(in section: Int) -> Int {
        numberOfItemsInSection[section] ?? 0
    }

    func configuration(at indexPath: IndexPath) -> ItemModel.Configuration {
        let preferredSize = preferredSizeAtIndexPath[indexPath] ?? settings.estimatedItemSize ?? .zero
        return .init(
            alignment: alignmentAtIndexPath[indexPath] ?? .fullWidth,
            pinningType: pinningTypeAtIndexPath[indexPath],
            preferredSize: preferredSize,
            calculatedSize: calculatedSizeAtIndexPath[indexPath] ?? preferredSize,
            interItemSpacing: interItemSpacingAtIndexPath[indexPath] ?? settings.interItemSpacing
        )
    }

    func alignmentForItem(_ chatLayout: CollectionViewChatLayout, at indexPath: IndexPath) -> ChatItemAlignment {
        .fullWidth
    }

    func sizeForItem(_ chatLayout: CollectionViewChatLayout, at indexPath: IndexPath) -> ItemSize {
        .estimated(settings.estimatedItemSize!)
    }

    func pinningTypeForItem(_ chatLayout: CollectionViewChatLayout, at indexPath: IndexPath) -> ChatItemPinningType? {
        pinningTypeAtIndexPath[indexPath]
    }

    func interSectionSpacing(at sectionIndex: Int) -> CGFloat {
        interSectionSpacingAtSection[sectionIndex] ?? settings.interSectionSpacing
    }

    func getPreparedSections() -> ContiguousArray<SectionModel<MockCollectionLayout>> {
        var sections: ContiguousArray<SectionModel<MockCollectionLayout>> = []
        for sectionIndex in 0..<numberOfItemsInSection.count {
            var items: ContiguousArray<ItemModel> = []
            for itemIndex in 0..<numberOfItems(in: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                items.append(ItemModel(with: configuration(at: indexPath)))
            }

            var section = SectionModel(
                interSectionSpacing: interSectionSpacing(at: sectionIndex),
                items: items,
                collectionLayout: self
            )
            section.assembleLayout()
            sections.append(section)
        }
        return sections
    }
}
