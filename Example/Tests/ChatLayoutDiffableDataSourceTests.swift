//
// ChatLayout
// ChatLayoutDiffableDataSourceTests.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

@testable import ChatLayout
import UIKit
import XCTest

@MainActor
final class ChatLayoutDiffableDataSourceTests: XCTestCase {
    func testApplyingInitialSnapshotCommitsModelsBeforeReloadingData() {
        let collectionView = DiffableDataSourceCollectionViewMock()
        var committedItems = [Int]()
        var completionWasCalled = false
        collectionView.onReloadData = {
            XCTAssertEqual(committedItems, [10, 20])
        }
        let dataSource = ChatLayoutDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }
        let snapshot = makeSnapshot(items: [10, 20])

        dataSource.applySnapshotUsingReloadData(snapshot, commitAlongsideUpdates: {
            committedItems = [10, 20]
        }, completion: {
            completionWasCalled = true
        })

        XCTAssertEqual(collectionView.reloadDataCallCount, 1)
        XCTAssertEqual(dataSource.snapshot?.sectionIdentifiers, [0])
        XCTAssertEqual(dataSource.snapshot?.itemIdentifiers, [10, 20])
        XCTAssertEqual(dataSource.indexPath(for: 20), IndexPath(item: 1, section: 0))
        XCTAssertEqual(dataSource.itemIdentifier(for: IndexPath(item: 0, section: 0)), 10)
        XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 1)
        XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 2)
        XCTAssertTrue(completionWasCalled)
    }

    func testApplyingSnapshotPerformsBatchUpdatesAndCommitsModelsBeforeViewUpdates() {
        let collectionView = DiffableDataSourceCollectionViewMock()
        let dataSource = ChatLayoutDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }
        dataSource.applySnapshotUsingReloadData(makeSnapshot(items: [10]), commitAlongsideUpdates: {})
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.addSubview(collectionView)
        collectionView.reset()
        var committedItems = [10]
        var completionWasCalled = false
        collectionView.onInsertItems = { _ in
            XCTAssertEqual(committedItems, [10, 20])
        }

        dataSource.apply(makeSnapshot(items: [10, 20]), animatingDifferences: true, commitAlongsideUpdates: {
            committedItems = [10, 20]
        }, completion: {
            completionWasCalled = true
        })

        XCTAssertNotNil(collectionView.window)
        XCTAssertEqual(collectionView.performBatchUpdatesCallCount, 1)
        XCTAssertEqual(collectionView.insertedItems, [IndexPath(item: 1, section: 0)])
        XCTAssertTrue(completionWasCalled)
        _ = window
    }

    func testReconfiguringItemUsesOldIndexPathAndCallsCellReconfigurationHandler() throws {
        let collectionView = DiffableDataSourceCollectionViewMock()
        let expectedCell = UICollectionViewCell()
        var providedItemID: Int?
        var reconfiguredCell: UICollectionViewCell?
        let dataSource = ChatLayoutDiffableDataSource<Int, Int>(
            collectionView: collectionView,
            onCellReconfiguration: { cell in
                reconfiguredCell = cell
            },
            cellProvider: { _, _, itemID in
                providedItemID = itemID
                return expectedCell
            }
        )
        dataSource.applySnapshotUsingReloadData(makeSnapshot(items: [10]), commitAlongsideUpdates: {})
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.addSubview(collectionView)
        collectionView.reset()
        var snapshot = makeSnapshot(items: [10])
        snapshot.reconfigureItems([10])

        dataSource.apply(snapshot, animatingDifferences: true, commitAlongsideUpdates: {})

        XCTAssertEqual(collectionView.performBatchUpdatesCallCount, 1)
        XCTAssertEqual(collectionView.reconfiguredItems, [IndexPath(item: 0, section: 0)])
        XCTAssertEqual(providedItemID, 10)
        XCTAssertTrue(try XCTUnwrap(reconfiguredCell) === expectedCell)
        _ = window
    }

    private func makeSnapshot(items: [Int]) -> NSDiffableDataSourceSnapshot<Int, Int> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        return snapshot
    }
}

@MainActor
private final class DiffableDataSourceCollectionViewMock: UICollectionView {
    var onReloadData: (() -> Void)?
    var onInsertItems: (([IndexPath]) -> Void)?

    private(set) var reloadDataCallCount = 0
    private(set) var performBatchUpdatesCallCount = 0
    private(set) var insertedItems: [IndexPath] = []
    private(set) var reconfiguredItems: [IndexPath] = []

    init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func reloadData() {
        reloadDataCallCount += 1
        onReloadData?()
    }

    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        performBatchUpdatesCallCount += 1
        updates?()
        completion?(true)
    }

    override func insertItems(at indexPaths: [IndexPath]) {
        insertedItems.append(contentsOf: indexPaths)
        onInsertItems?(indexPaths)
    }

    override func reconfigureItems(at indexPaths: [IndexPath]) {
        reconfiguredItems.append(contentsOf: indexPaths)
        for indexPath in indexPaths {
            guard let dataSource else {
                continue
            }
            _ = dataSource.collectionView(self, cellForItemAt: indexPath)
        }
    }

    func reset() {
        reloadDataCallCount = 0
        performBatchUpdatesCallCount = 0
        insertedItems = []
        reconfiguredItems = []
    }
}

@MainActor
final class PinnedItemAnimationTests: XCTestCase {
    func testPinnedCellStaysAtTopDuringAnimatedInsertions() throws {
        try assertPinnedCellStaysAtTopDuringAnimatedInsertions(estimatedHeight: nil)
    }

    func testPinnedCellStaysAtTopDuringOverestimatedInsertions() throws {
        try assertPinnedCellStaysAtTopDuringAnimatedInsertions(estimatedHeight: 120)
    }

    func testPinnedCellStaysAtTopDuringUnderestimatedInsertions() throws {
        try assertPinnedCellStaysAtTopDuringAnimatedInsertions(estimatedHeight: 20)
    }

    private func assertPinnedCellStaysAtTopDuringAnimatedInsertions(estimatedHeight: CGFloat?) throws {
        let layout = CollectionViewChatLayout()
        layout.keepContentOffsetAtBottomOnBatchUpdates = true
        layout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
        let source = PinnedItemAnimationDataSource()
        source.estimatedHeight = estimatedHeight
        layout.delegate = source
        let controller = UIViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        let collectionView = UICollectionView(frame: controller.view.bounds, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(GrowingResponseCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = source
        controller.view.addSubview(collectionView)
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.contentOffset.y = layout.collectionViewContentSize.height - collectionView.bounds.height
        collectionView.layoutIfNeeded()
        CATransaction.flush()
        let dateIndexPath = IndexPath(item: 0, section: 0)
        let dateCell = try XCTUnwrap(collectionView.cellForItem(at: dateIndexPath))
        for item in [30, 10, 1] {
            let completed = expectation(description: "Insertion completed")
            collectionView.performBatchUpdates {
                source.itemCount += 1
                source.estimatedItemIndex = item
                collectionView.insertItems(at: [IndexPath(item: item, section: 0)])
            } completion: { _ in
                completed.fulfill()
            }
            for delay in [0.02, 0.08, 0.16, 0.25] {
                let sampled = expectation(description: "Insertion at \(delay)")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    XCTAssertTrue(collectionView.cellForItem(at: dateIndexPath) === dateCell)
                    if let cellLayer = dateCell.layer.presentation(),
                       let collectionLayer = collectionView.layer.presentation() {
                        XCTAssertEqual(
                            cellLayer.frame.minY - collectionLayer.bounds.minY,
                            0,
                            accuracy: 1,
                            "Item \(item), sample \(delay)"
                        )
                    } else {
                        XCTFail("Missing presentation layers")
                    }
                    sampled.fulfill()
                }
            }
            waitForExpectations(timeout: 3)
        }
    }

    func testPinnedCellStaysAtTopWhileAgentResponseGrows() throws {
        try assertPinnedCellStaysAtTopWhileAgentResponseGrows(updateInterval: 0.5)
    }

    func testPinnedCellStaysAtTopDuringOverlappingAgentUpdates() throws {
        try assertPinnedCellStaysAtTopWhileAgentResponseGrows(updateInterval: 0.1)
    }

    private func assertPinnedCellStaysAtTopWhileAgentResponseGrows(updateInterval: TimeInterval) throws {
        let layout = CollectionViewChatLayout()
        layout.keepContentOffsetAtBottomOnBatchUpdates = true
        layout.keepContentAtBottomOfVisibleArea = true
        layout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
        layout.settings.indexPathForExtendedLayout = IndexPath(item: 20, section: 0)
        let source = GrowingResponseDataSource()
        layout.delegate = source
        let controller = UIViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        let collectionView = UICollectionView(frame: controller.view.bounds, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(GrowingResponseCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = source
        controller.view.addSubview(collectionView)
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.contentOffset.y = 800
        collectionView.layoutIfNeeded()
        CATransaction.flush()
        let dateIndexPath = IndexPath(item: 0, section: 0)
        let dateCell = try XCTUnwrap(collectionView.cellForItem(at: dateIndexPath))
        let responseIndexPath = IndexPath(item: 21, section: 0)
        let heights: [CGFloat] = [80, 240, 900, 960, 1020]
        for (index, height) in heights.enumerated() {
            let completed = expectation(description: "Reconfiguration completed")
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * updateInterval) {
                source.responseHeight = height
                collectionView.performBatchUpdates {
                    collectionView.reconfigureItems(at: [responseIndexPath])
                    layout.reconfigureItems(at: [responseIndexPath])
                } completion: { _ in
                    completed.fulfill()
                }
            }
        }
        let duration = Double(heights.count - 1) * updateInterval + 0.5
        for delay in stride(from: 0.02, through: duration, by: 0.02) {
            let sampled = expectation(description: "Growing response at \(delay)")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                XCTAssertTrue(collectionView.cellForItem(at: dateIndexPath) === dateCell)
                if let cellLayer = dateCell.layer.presentation(),
                   let collectionLayer = collectionView.layer.presentation() {
                    XCTAssertEqual(
                        cellLayer.frame.minY - collectionLayer.bounds.minY,
                        0,
                        accuracy: 1,
                        "Sample \(delay), cell \(dateCell.frame.minY), offset \(collectionView.contentOffset.y)"
                    )
                    XCTAssertEqual(cellLayer.opacity, 1)
                } else {
                    XCTFail("Missing presentation layers")
                }
                sampled.fulfill()
            }
        }
        waitForExpectations(timeout: duration + 2)
        XCTAssertEqual(collectionView.cellForItem(at: responseIndexPath)?.bounds.height, heights.last)
    }

    func testPinnedCellStaysAtTopDuringAnimatedInsetChange() throws {
        let layout = CollectionViewChatLayout()
        layout.keepContentOffsetAtBottomOnBatchUpdates = true
        let source = PinnedItemAnimationDataSource()
        let controller = UIViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.isHidden = false
        let collectionView = OffsetRestorationCollectionView(frame: controller.view.bounds, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = source
        layout.delegate = source
        controller.view.addSubview(collectionView)
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.contentOffset.y = 200
        collectionView.layoutIfNeeded()
        CATransaction.flush()
        let indexPath = IndexPath(item: 0, section: 0)
        let cell = try XCTUnwrap(collectionView.cellForItem(at: indexPath))
        for bottomInset: CGFloat in [150, 250, 75, 0] {
            let snapshot = try XCTUnwrap(layout.getContentOffsetSnapshot(from: .bottom))
            let completed = expectation(description: "Animation completed")
            UIView.animate(withDuration: 0.4, animations: {
                collectionView.contentInset.bottom = bottomInset
                collectionView.onNextLayout = {
                    let attributes = layout.layoutAttributesForElements(in: collectionView.bounds)
                    XCTAssertEqual(attributes?.map(\.indexPath), [indexPath])
                    XCTAssertNotNil(layout.layoutAttributesForItem(at: indexPath))
                    XCTAssertNil(layout.layoutAttributesForItem(at: IndexPath(item: 10, section: 0)))
                }
                layout.restoreContentOffset(with: snapshot)
                XCTAssertNil(collectionView.onNextLayout)
            }, completion: { _ in
                completed.fulfill()
            })
            for delay in [0.05, 0.15, 0.25] {
                let sampled = expectation(description: "Pinned cell at \(delay)")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    XCTAssertTrue(collectionView.cellForItem(at: indexPath) === cell)
                    if let cellLayer = cell.layer.presentation(),
                       let collectionLayer = collectionView.layer.presentation() {
                        XCTAssertEqual(cellLayer.frame.minY - collectionLayer.bounds.minY, 0, accuracy: 1, "Inset \(bottomInset), sample \(delay), model cell \(cell.frame.minY), offset \(collectionView.contentOffset.y)")
                        XCTAssertEqual(cellLayer.opacity, 1)
                    } else {
                        XCTFail("Missing presentation layers")
                    }
                    let attributes = layout.layoutAttributesForItem(at: indexPath) as? ChatLayoutAttributes
                    XCTAssertEqual(attributes?.pinningProgress, 1)
                    sampled.fulfill()
                }
            }
            waitForExpectations(timeout: 3)
        }
        window.isHidden = true
    }

    func testPinnedAttributesSurviveInsetUpdateAnimation() throws {
        let layout = CollectionViewChatLayout()
        let source = PinnedItemAnimationDataSource()
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 480),
            collectionViewLayout: layout
        )
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = source
        layout.delegate = source
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.contentOffset.y = 200
        collectionView.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)
        let pinned = try XCTUnwrap(layout.layoutAttributesForItem(at: indexPath) as? ChatLayoutAttributes)
        XCTAssertTrue(pinned.isPinned)
        XCTAssertEqual(pinned.pinningProgress, 1)

        layout.prepare(forCollectionViewUpdates: [])
        collectionView.contentInset.bottom = 100
        layout.prepare()

        let appearing = try XCTUnwrap(layout.initialLayoutAttributesForAppearingItem(at: indexPath) as? ChatLayoutAttributes)
        XCTAssertTrue(appearing.isPinned)
        XCTAssertEqual(appearing.pinningProgress, 1)
        XCTAssertEqual(appearing.frame.minY, collectionView.contentOffset.y)

        let disappearing = try XCTUnwrap(layout.finalLayoutAttributesForDisappearingItem(at: indexPath) as? ChatLayoutAttributes)
        XCTAssertTrue(disappearing.isPinned)
        XCTAssertEqual(disappearing.pinningProgress, 1)
        XCTAssertEqual(disappearing.frame.minY, collectionView.contentOffset.y)
        layout.finalizeCollectionViewUpdates()
    }
}

@MainActor
private final class PinnedItemAnimationDataSource: NSObject, UICollectionViewDataSource, ChatLayoutDelegate {
    var itemCount = 30
    var estimatedHeight: CGFloat?
    var estimatedItemIndex: Int?

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        itemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    }

    func sizeForItem(_ chatLayout: CollectionViewChatLayout, at indexPath: IndexPath) -> ItemSize {
        if let estimatedHeight, indexPath.item == estimatedItemIndex {
            .estimated(CGSize(width: 320, height: estimatedHeight))
        } else {
            .exact(CGSize(width: 320, height: 40))
        }
    }

    func pinningTypeForItem(_ chatLayout: CollectionViewChatLayout, at indexPath: IndexPath) -> ChatItemPinningType? {
        indexPath.item == 0 ? .top : nil
    }
}

@MainActor
private final class OffsetRestorationCollectionView: UICollectionView {
    var onNextLayout: (() -> Void)?

    override func layoutIfNeeded() {
        let callback = onNextLayout
        onNextLayout = nil
        callback?()
        super.layoutIfNeeded()
    }
}

@MainActor
private final class GrowingResponseDataSource: NSObject, UICollectionViewDataSource, ChatLayoutDelegate {
    var responseHeight: CGFloat = 40

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        22
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? GrowingResponseCell else {
            preconditionFailure("Unexpected cell type")
        }
        cell.requiredHeight = indexPath.item == 21 ? responseHeight : 40
        return cell
    }

    func sizeForItem(_ chatLayout: CollectionViewChatLayout, at indexPath: IndexPath) -> ItemSize {
        .estimated(CGSize(width: 320, height: 40))
    }

    func pinningTypeForItem(_ chatLayout: CollectionViewChatLayout, at indexPath: IndexPath) -> ChatItemPinningType? {
        indexPath.item == 0 ? .top : nil
    }
}

@MainActor
private final class GrowingResponseCell: UICollectionViewCell {
    var requiredHeight: CGFloat = 40

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else {
            preconditionFailure("Unexpected attributes type")
        }
        attributes.size.height = requiredHeight
        return attributes
    }
}
