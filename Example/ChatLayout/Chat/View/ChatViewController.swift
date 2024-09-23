//
// ChatLayout
// ChatViewController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import DifferenceKit
import Foundation
import FPSCounter
import InputBarAccessoryView
import UIKit

struct AccessoryConfiguration: Equatable {
    public var frame: CGRect
    public var alpha: CGFloat
    public var isHidden: Bool
    
    public init(frame: CGRect,
                alpha: CGFloat = 1,
                isHidden: Bool = false) {
        self.frame = frame
        self.alpha = alpha
        self.isHidden = isHidden
    }

    public init(_ cell: UICollectionViewCell) {
        self.frame = cell.frame
        self.alpha = cell.alpha
        self.isHidden = cell.isHidden
    }
}

final class AccesoryCell: UIView {
    final let reuseIdentifier: String
    final let customView: UIView
    final var configuration: AccessoryConfiguration

    final var id: String

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(customView: UIView, configuration: AccessoryConfiguration, id: String) {
        self.reuseIdentifier = "\(ObjectIdentifier(type(of: customView)))"
        self.customView = customView
        self.configuration = configuration
        self.id = id
        super.init(frame: configuration.frame)
        insetsLayoutMarginsFromSafeArea = false
        translatesAutoresizingMaskIntoConstraints = true
        customView.translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = []
        autoresizesSubviews = false

        addSubview(customView)
        commitGeometryUpdates()
    }

    func commitGeometryUpdates() {
        if transform != .identity {
            transform = .identity
        }
        self.frame = configuration.frame
        customView.frame = CGRect(origin: .zero, size: configuration.frame.size)

        if alpha != configuration.alpha {
            alpha = min(0.5, configuration.alpha)
        }

        if isHidden != configuration.isHidden {
            isHidden = configuration.isHidden
        }
    }

}

final class MyCollectionView: UICollectionView {
    struct WeakAccessoryCellReference {
        let id: String
        weak var cell: UICollectionViewCell?
    }
    struct WeakCellReference {
        weak var cell: UICollectionViewCell?
    }
    private var lastCycleCells: Array<WeakCellReference> = []
    private var lastCycleAccesoryCells: Array<WeakAccessoryCellReference> = []
    private var currentCellsDict = [String: AccesoryCell]()
    private var dequeueCellsDictionary: [String: Set<AccesoryCell>] = [:]

    func dequeueReusableViewForIndex<View: UIView>(reuseIdentifier: String? = nil) -> View? {
        let reuseIdentifier = reuseIdentifier ?? "\(ObjectIdentifier(View.self))"
        guard let cell = dequeueCellsDictionary[reuseIdentifier]?.popFirst() else {
            return nil
        }
        guard let view = cell.customView as? View else {
            fatalError("Internal inconsistency")
        }
        return view
    }

    private func reuseCell(_ cell: AccesoryCell) {
        var configuration = cell.configuration
        configuration.alpha = 1
        configuration.isHidden = true
        cell.configuration = configuration
        cell.commitGeometryUpdates()

        let reuseIdentifier = cell.reuseIdentifier
        dequeueCellsDictionary[reuseIdentifier, default: []].insert(cell)
    }


    private func getVisibleCells() -> [(indexPath: IndexPath?, cell: UICollectionViewCell)] {
        subviews.compactMap { view -> UICollectionViewCell? in
            guard let view = view as? UICollectionViewCell,
                  !view.isHidden else {
                return nil
            }
            return view
        }.map { cell in
            (indexPath: indexPath(for: cell), cell: cell)
        }
    }

    override func layoutSubviews() {
        let oldContentOffset = contentOffset
        super.layoutSubviews()

        let allVisibleCells = getVisibleCells()

        let jsutLastCycleCells = Set(lastCycleCells.compactMap({ $0.cell }))
        let deletedCells = allVisibleCells.filter({ $0.indexPath == nil }).filter({ jsutLastCycleCells.contains($0.cell) }).map({ $0.cell })

        let cellsGrouppedByReplyId = Dictionary(grouping: allVisibleCells, by: { $0.cell.replyPattern?.replyUUID })
        var pathSegmentsById = [String: [(segment: ReplySegments, till: CGFloat)]]()
        let visibleAccessyCells = cellsGrouppedByReplyId.reduce(into: [(id: String, frame: CGRect, cell: UICollectionViewCell, indexPath: IndexPath?, duration: CGFloat)]()) { result, element in
            guard let id = element.key else {
                return
            }
            let items = element.value.sorted(by: { $0.cell.frame.minY < $1.cell.frame.minY })
            var combineRect: CGRect? = nil
            var pathSegments = [(segment: ReplySegments, till: CGFloat)]()
            var currentSegmentHasher = Hasher()

            for item in items {
                guard let replyPattern = item.cell.replyPattern,
                        !deletedCells.contains(item.cell) else {
                    continue
                }
                currentSegmentHasher.combine(replyPattern.id)
                currentSegmentHasher.combine(replyPattern.replyUUID)
                var currentRect: CGRect
                if let combineRect {
                    let difference = item.cell.frame.minY - combineRect.maxY
                    if difference.rounded(.down) != 0 {
                        pathSegments.append((segment: .line, till: combineRect.height + difference))
                    }
                    currentRect = combineRect.union(item.cell.frame)
                } else {
                    currentRect = item.cell.frame
                }
                if let replyBreak = item.cell.replyBreak {
                    let top = self.convert(CGPoint(x: 0, y: replyBreak.top), from: item.cell)

                    var previousRect = currentRect.intersection(CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: top.y))
                    previousRect.origin.x = 20
                    previousRect.size.width = 18

                    let accessoryId = "\(id)-\(currentSegmentHasher.finalize())"
                    pathSegments.append((segment: replyPattern.replySegment, till: previousRect.height))
                    pathSegmentsById[accessoryId] = pathSegments
                    pathSegments = .init()

                    let duration = item.cell.layer.animation(forKey: "position")?.duration
                    result.append((id: accessoryId, frame: previousRect, cell: item.cell, indexPath: item.indexPath, duration: duration ?? 0))

                    currentSegmentHasher = Hasher()
                    let bottom = self.convert(CGPoint(x: 0, y: replyBreak.bottom), from: item.cell)
                    var nextRect: CGRect
                    if bottom.y < currentRect.maxY {
                        nextRect = currentRect.intersection(CGRect(origin: .init(x: 0, y: bottom.y), size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)))
                    } else {
                        nextRect = CGRect(origin: .init(x: item.cell.frame.minX, y: bottom.y), size: .zero)
                    }

                    if !nextRect.isNull,
                        items.last?.cell !== item.cell {
                        combineRect = nextRect
                    } else {
                        combineRect = nil
                    }
                } else {
                    pathSegments.append((segment: replyPattern.replySegment, till: currentRect.height))
                    combineRect = currentRect
                }
            }
            let accessoryId = "\(id)-\(currentSegmentHasher.finalize())"
            if var combineRect,
                let lastElement = items.last {
                combineRect.origin.x = 20
                combineRect.size.width = 18
                let duration = lastElement.cell.layer.animation(forKey: "position")?.duration
                result.append((id: accessoryId, frame: combineRect, cell: lastElement.cell, indexPath: lastElement.indexPath, duration: duration ?? 0))
            }
            if !pathSegments.isEmpty {
                pathSegmentsById[accessoryId] = pathSegments
            }
        }

        let currentlyPresentCells = visibleAccessyCells.compactMap { item -> (id: String, cell: AccesoryCell, originalCell: UICollectionViewCell, frame: CGRect, duration: CGFloat)? in
            guard let cell = currentCellsDict[item.id] else {
                return nil
            }
            return (id: item.id, cell: cell, originalCell: item.cell, frame: item.frame, duration: item.duration)
        }

        for currentCell in currentlyPresentCells {
            if let shape = pathSegmentsById[currentCell.id] {
                (currentCell.cell.customView as? BezierView)?.setupWith(.init(segments: shape))
            } else {
                (currentCell.cell.customView as? BezierView)?.setupWith(nil)
            }

            var configuration = currentCell.cell.configuration
            configuration.frame = currentCell.frame
            if currentCell.cell.configuration != configuration {
                currentCell.cell.configuration = configuration
                let duration = currentCell.originalCell.layer.animation(forKey: "position")?.duration ?? UIView.inheritedAnimationDuration
                if duration == 0 {
                    currentCell.cell.commitGeometryUpdates()
                } else {
                    UIView.transition(with: self,
                                      duration: duration,
                                      options: .beginFromCurrentState,
                                      animations: {
                        currentCell.cell.configuration = configuration
                        currentCell.cell.commitGeometryUpdates()
                                      })
                }
            }
        }

        let appearingIndexes = visibleAccessyCells.compactMap({ cell -> (id: String, cell: UICollectionViewCell, frame: CGRect)? in
            guard !currentlyPresentCells.contains(where: { $0.id == cell.id }) else {
                return nil
            }
            return (id: cell.id, cell: cell.cell, frame: cell.frame)
        })

        let cellsToRemove = currentCellsDict.filter({ cell in !currentlyPresentCells.contains(where: { $0.cell === cell.value }) })

        currentCellsDict = currentCellsDict.filter({ !cellsToRemove.values.contains($0.value) })

        for appearingIndex in appearingIndexes {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let customView: BezierView = dequeueReusableViewForIndex() ?? BezierView()
            if let shape = pathSegmentsById[appearingIndex.id] {
                customView.setupWith(.init(segments: shape))
            } else {
                customView.setupWith(nil)
            }
            var cell: AccesoryCell
            var configuration = AccessoryConfiguration(appearingIndex.cell)
            configuration.frame = appearingIndex.frame

            var initialConfiguration = configuration
            initialConfiguration.alpha = 0
            if let value = (appearingIndex.cell.layer.animation(forKey: "position") as? CABasicAnimation)?.fromValue as? CGPoint {
                initialConfiguration.frame.origin.y += value.y - (contentOffset.y - oldContentOffset.y)
            } else {
                initialConfiguration.frame.origin.y += contentOffset.y - oldContentOffset.y
            }
            if let value = (appearingIndex.cell.layer.animation(forKey: "opacity") as? CABasicAnimation)?.fromValue as? CGFloat {
                initialConfiguration.alpha = value
            }

            if let localCell = customView.superview as? AccesoryCell {
                cell = localCell
                cell.id = appearingIndex.id
                cell.configuration = initialConfiguration
                UIView.performWithoutAnimation {
                    cell.commitGeometryUpdates()
                }
            } else {
                let newCell = AccesoryCell(customView: customView, configuration: initialConfiguration, id: appearingIndex.id)
                addSubview(newCell)
                cell = newCell
            }
            UIView.performWithoutAnimation({
                cell.center.y -= oldContentOffset.y - contentOffset.y
            })

            cell.setNeedsLayout()
            CATransaction.commit()

            let duration: TimeInterval
            if UIView.inheritedAnimationDuration == 0,
               let animationKey = appearingIndex.cell.layer.animationKeys()?.first,
               let animation = appearingIndex.cell.layer.animation(forKey: animationKey) {
                duration = animation.duration
            } else {
                duration = UIView.inheritedAnimationDuration
            }
            currentCellsDict[cell.id] = cell

            if duration != 0 {
                UIView.transition(with: self,
                                  duration: duration,
                                  options: .beginFromCurrentState,
                                  animations: {
                                        cell.configuration = configuration
                                        cell.commitGeometryUpdates()
                                  })
            } else {
                UIView.performWithoutAnimation {
                    cell.configuration = configuration
                    cell.commitGeometryUpdates()
                }
            }
        }


        for cellToRemove in cellsToRemove {
            let oldCell = lastCycleAccesoryCells.first(where: { $0.id == cellToRemove.key })?.cell
            let duration: TimeInterval
            if UIView.inheritedAnimationDuration == 0,
               let oldCell,
               let animationKey = oldCell.layer.animationKeys()?.first,
               let animation = oldCell.layer.animation(forKey: animationKey) {
                duration = animation.duration
            } else {
                duration = UIView.inheritedAnimationDuration
            }
            print("REMOVE \(cellToRemove.key)")
            if duration != 0 {
                UIView.transition(with: self,
                                  duration: duration,
                                  options: .beginFromCurrentState,
                                  animations: { [weak self] in
                                      guard let self else {
                                          return
                                      }
                    if let oldCell = lastCycleAccesoryCells.first(where: { $0.id == cellToRemove.key })?.cell {
//                        var configuration = AccessoryConfiguration(oldCell)
//                        configuration.isHidden = false
                        var configuration = cellToRemove.value.configuration
                        configuration.frame.center = oldCell.frame.center
                        cellToRemove.value.configuration = configuration
                    } else {
                        cellToRemove.value.configuration.alpha = 0
                    }
                    cellToRemove.value.commitGeometryUpdates()
                                  }, completion: { [weak self] _ in
                                      guard let self else {
                                          return
                                      }
                                      print("REMOVED \(cellToRemove.key)")
                                      reuseCell(cellToRemove.value)
    //                                  cellToRemove.value.removeFromSuperview()
                                  })
            } else {
                UIView.performWithoutAnimation {
                    reuseCell(cellToRemove.value)
                }
            }

        }

        print("\(Self.self) \(#function) FINISH\n\n\n")

        lastCycleAccesoryCells = visibleAccessyCells.compactMap({ item -> WeakAccessoryCellReference? in
            return WeakAccessoryCellReference(id: item.id, cell: item.cell)
        })

        lastCycleCells = allVisibleCells.map({
            return WeakCellReference(cell: $0.cell)
        })
    }
}

private let replyInfoKey = UnsafeRawPointer(UnsafeMutablePointer.allocate(capacity: 0))
private let replyBreakKey = UnsafeRawPointer(UnsafeMutablePointer.allocate(capacity: 0))

extension UICollectionViewCell {
    var replyPattern: ReplyPathPattern? {
        get {
            objc_getAssociatedObject(self, replyInfoKey) as? ReplyPathPattern
        }
        set {
            objc_setAssociatedObject(self, replyInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var replyBreak: (top: CGFloat, bottom: CGFloat)? {
        get {
            objc_getAssociatedObject(self, replyBreakKey) as? (top: CGFloat, bottom: CGFloat)
        }
        set {
            objc_setAssociatedObject(self, replyBreakKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// It's advisable to continue using the reload/reconfigure method, especially when multiple changes occur concurrently in an animated fashion.
// This approach ensures that the ChatLayout can handle these changes while maintaining the content offset accurately.
// Consider using it when no better alternatives are available.
let enableSelfSizingSupport = false

// By setting this flag to true you can test reconfigure instead of reload.
let enableReconfigure = false

final class ChatViewController: UIViewController {
    private enum ReactionTypes {
        case delayedUpdate
    }

    private enum InterfaceActions {
        case changingKeyboardFrame
        case changingContentInsets
        case changingFrameSize
        case sendingMessage
        case scrollingToTop
        case scrollingToBottom
        case showingPreview
        case showingAccessory
        case updatingCollectionInIsolation
    }

    private enum ControllerActions {
        case loadingInitialMessages
        case loadingPreviousMessages
        case updatingCollection
    }

    override var inputAccessoryView: UIView? {
        inputBarView
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()
    private let editNotifier: EditNotifier
    private let swipeNotifier: SwipeNotifier
    private var collectionView: UICollectionView!
    private var chatLayout = CollectionViewChatLayout()
    private let inputBarView = InputBarAccessoryView()
    private let chatController: ChatController
    private let dataSource: ChatCollectionDataSource
    private let fpsCounter = FPSCounter()
    private let fpsView = EdgeAligningView<UILabel>(frame: CGRect(origin: .zero, size: .init(width: 30, height: 30)))
    private var animator: ManualAnimator?

    private var translationX: CGFloat = 0
    private var currentOffset: CGFloat = 0

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleRevealPan(_:)))
        gesture.delegate = self
        return gesture
    }()

    init(chatController: ChatController,
         dataSource: ChatCollectionDataSource,
         editNotifier: EditNotifier,
         swipeNotifier: SwipeNotifier) {
        self.chatController = chatController
        self.dataSource = dataSource
        self.editNotifier = editNotifier
        self.swipeNotifier = swipeNotifier
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "Use init(messageController:) instead")
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }

    @available(*, unavailable, message: "Use init(messageController:) instead")
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fpsCounter.delegate = self
        fpsCounter.startTracking()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        inputBarView.delegate = self

        fpsView.translatesAutoresizingMaskIntoConstraints = false
        fpsView.flexibleEdges = [.trailing]
        fpsView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16)
        fpsView.customView.font = .preferredFont(forTextStyle: .caption2)
        fpsView.customView.text = "FPS: unknown"
        if #available(iOS 13.0, *) {
            fpsView.backgroundColor = .systemBackground
            fpsView.customView.textColor = .systemGray3
        } else {
            fpsView.backgroundColor = .white
            fpsView.customView.textColor = .lightGray
        }
        inputBarView.topStackView.addArrangedSubview(fpsView)
        inputBarView.shouldAnimateTextDidChangeLayout = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Show Keyboard", style: .plain, target: self, action: #selector(ChatViewController.showHideKeyboard))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(ChatViewController.setEditNotEdit))

        chatLayout.settings.interItemSpacing = 8
        chatLayout.settings.interSectionSpacing = 8
        chatLayout.settings.additionalInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
        chatLayout.keepContentAtBottomOfVisibleArea = true

        collectionView = MyCollectionView(frame: view.frame, collectionViewLayout: chatLayout)
        view.addSubview(collectionView)
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = dataSource
        chatLayout.delegate = dataSource
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive

        /// https://openradar.appspot.com/40926834
        collectionView.isPrefetchingEnabled = false

        collectionView.contentInsetAdjustmentBehavior = .always
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = true
        }

        if #available(iOS 16.0, *),
           enableSelfSizingSupport {
            collectionView.selfSizingInvalidation = .enabled
            chatLayout.supportSelfSizingInvalidation = true
        }

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.frame = view.bounds
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        dataSource.prepare(with: collectionView)

        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { sections in
            self.currentControllerActions.options.remove(.loadingInitialMessages)
            self.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
        }

        KeyboardListener.shared.add(delegate: self)
        collectionView.addGestureRecognizer(panGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard isViewLoaded else {
            return
        }
        currentInterfaceActions.options.insert(.changingFrameSize)
        let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setNeedsLayout()
        coordinator.animate(alongsideTransition: { _ in
            // Gives nicer transition behaviour
            // self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.performBatchUpdates(nil)
        }, completion: { _ in
            if let positionSnapshot,
               !self.isUserInitiatedScrolling {
                // As contentInsets may change when size transition has already started. For example, `UINavigationBar` height may change
                // to compact and back. `CollectionViewChatLayout` may not properly predict the final position of the element. So we try
                // to restore it after the rotation manually.
                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.currentInterfaceActions.options.remove(.changingFrameSize)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }

    @objc
    private func showHideKeyboard() {
        if inputBarView.inputTextView.isFirstResponder {
            navigationItem.leftBarButtonItem?.title = "Show Keyboard"
            inputBarView.inputTextView.resignFirstResponder()
        } else {
            navigationItem.leftBarButtonItem?.title = "Hide Keyboard"
            inputBarView.inputTextView.becomeFirstResponder()
        }
    }

    @objc
    private func setEditNotEdit() {
        isEditing = !isEditing
        editNotifier.setIsEditing(isEditing, duration: .animated(duration: 0.25))
        navigationItem.rightBarButtonItem?.title = isEditing ? "Done" : "Edit"
        chatLayout.invalidateLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        swipeNotifier.setAccessoryOffset(UIEdgeInsets(top: view.safeAreaInsets.top,
                                                      left: view.safeAreaInsets.left + chatLayout.settings.additionalInsets.left,
                                                      bottom: view.safeAreaInsets.bottom,
                                                      right: view.safeAreaInsets.right + chatLayout.settings.additionalInsets.right))
    }

    // Apple doesnt return sometimes inputBarView back to the app. This is an attempt to fix that
    // See: https://github.com/ekazaev/ChatLayout/issues/24
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if inputBarView.superview == nil,
           topMostViewController() is ChatViewController {
            DispatchQueue.main.async { [weak self] in
                self?.reloadInputViews()
            }
        }
    }
}

extension ChatViewController: UIScrollViewDelegate {
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView.contentSize.height > 0,
              !currentInterfaceActions.options.contains(.showingAccessory),
              !currentInterfaceActions.options.contains(.showingPreview),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return false
        }
        // Blocking the call of loadPreviousMessages() as UIScrollView behaves the way that it will scroll to the top even if we keep adding
        // content there and keep changing the content offset until it actually reaches the top. So instead we wait until it reaches the top and initiate
        // the loading after.
        currentInterfaceActions.options.insert(.scrollingToTop)
        return true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages) else {
            return
        }
        currentInterfaceActions.options.remove(.scrollingToTop)
        loadPreviousMessages()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentControllerActions.options.contains(.updatingCollection), collectionView.isDragging {
            // Interrupting current update animation if user starts to scroll while batchUpdate is performed. It helps to
            // avoid presenting blank area if user scrolls out of the animation rendering area.
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates({}, completion: { _ in
                    let context = ChatLayoutInvalidationContext()
                    context.invalidateLayoutMetrics = false
                    self.collectionView.collectionViewLayout.invalidateLayout(with: context)
                })
            }
        }
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return
        }

        if scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + scrollView.bounds.height {
            loadPreviousMessages()
        }
    }

    private func loadPreviousMessages() {
        return
        // Blocking the potential multiple call of that function as during the content invalidation the contentOffset of the UICollectionView can change
        // in any way so it may trigger another call of that function and lead to unexpected behaviour/animation
//        currentControllerActions.options.insert(.loadingPreviousMessages)
//        chatController.loadPreviousMessages { [weak self] sections in
//            guard let self else {
//                return
//            }
//            // Reloading the content without animation just because it looks better is the scrolling is in process.
//            let animated = !isUserInitiatedScrolling
//            processUpdates(with: sections, animated: animated, requiresIsolatedProcess: false) {
//                self.currentControllerActions.options.remove(.loadingPreviousMessages)
//            }
//        }
    }

    fileprivate var isUserInitiatedScrolling: Bool {
        collectionView.isDragging || collectionView.isDecelerating
    }

    func scrollToBottom(completion: (() -> Void)? = nil) {
        // I ask content size from the layout because on IOs 12 collection view contains not updated one
        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)

        guard contentOffsetAtBottom.y > collectionView.contentOffset.y else {
            completion?()
            return
        }

        let initialOffset = collectionView.contentOffset.y
        let delta = contentOffsetAtBottom.y - initialOffset
        if abs(delta) > chatLayout.visibleBounds.height {
            // See: https://dasdom.dev/posts/scrolling-a-collection-view-with-custom-duration/
            animator = ManualAnimator()
            animator?.animate(duration: TimeInterval(0.25), curve: .easeInOut) { [weak self] percentage in
                guard let self else {
                    return
                }
                collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: initialOffset + (delta * percentage))
                if percentage == 1.0 {
                    animator = nil
                    let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .footer, edge: .bottom)
                    chatLayout.restoreContentOffset(with: positionSnapshot)
                    currentInterfaceActions.options.remove(.scrollingToBottom)
                    completion?()
                }
            }
        } else {
            currentInterfaceActions.options.insert(.scrollingToBottom)
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.collectionView.setContentOffset(contentOffsetAtBottom, animated: true)
            }, completion: { [weak self] _ in
                self?.currentInterfaceActions.options.remove(.scrollingToBottom)
                completion?()
            })
        }
    }
}

extension ChatViewController: UICollectionViewDelegate {
    @available(iOS 13.0, *)
    private func preview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String else {
            return nil
        }
        let components = identifier.split(separator: "|")
        guard components.count == 2,
              let sectionIndex = Int(components[0]),
              let itemIndex = Int(components[1]),
              let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: sectionIndex)) as? TextMessageCollectionCell else {
            return nil
        }

        let item = dataSource.sections[0].cells[itemIndex]
        switch item {
        case let .message(message, bubbleType: _):
            switch message.data {
            case .text:
                let parameters = UIPreviewParameters()
                // `UITargetedPreview` doesnt support image mask (Why?) like the one I use to mask the message bubble in the example app.
                // So I replaced default `ImageMaskedView` with `BezierMaskedView` that can uses `UIBezierPath` to mask the message view
                // instead. So we are reusing that path here.
                //
                // NB: This way of creating the preview is not valid for long texts as `UITextView` within message view uses `CATiledLayer`
                // to render its content, so it may not render itself fully when it is partly outside the collection view. You will have to
                // recreate a brand new view that will behave as a preview. It is outside of the scope of the example app.
                parameters.visiblePath = cell.customView.customView.customView.maskingPath
                var center = cell.customView.customView.customView.center
                center.x += (message.type.isIncoming ? cell.customView.customView.customView.offset : -cell.customView.customView.customView.offset) / 2

                return UITargetedPreview(view: cell.customView.customView.customView,
                                         parameters: parameters,
                                         target: UIPreviewTarget(container: cell.customView.customView, center: center))
            default:
                return nil
            }
        default:
            return nil
        }
    }

    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        preview(for: configuration)
    }

    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        preview(for: configuration)
    }

    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !currentInterfaceActions.options.contains(.showingPreview),
              !currentControllerActions.options.contains(.updatingCollection) else {
            return nil
        }
        let item = dataSource.sections[indexPath.section].cells[indexPath.item]
        switch item {
        case let .message(message, bubbleType: _):
            switch message.data {
            case let .text(body):
                let actions = [UIAction(title: "Copy", image: nil, identifier: nil) { [body] _ in
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = body
                }]
                let menu = UIMenu(title: "", children: actions)
                // Custom NSCopying identifier leads to the crash. No other requirements for the identifier to avoid the crash are provided.
                let identifier: NSString = "\(indexPath.section)|\(indexPath.item)" as NSString
                currentInterfaceActions.options.insert(.showingPreview)
                return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: { _ in menu })
            default:
                return nil
            }
        default:
            return nil
        }
    }

    @available(iOS 13.2, *)
    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        animator?.addCompletion {
            self.currentInterfaceActions.options.remove(.showingPreview)
        }
    }
}

extension ChatViewController: ChatControllerDelegate {
    func update(with sections: [Section], requiresIsolatedProcess: Bool) {
        // if `chatLayout.keepContentAtBottomOfVisibleArea` is enabled and content size is actually smaller than the visible size - it is better to process each batch update
        // in isolation. Example: If you insert a cell animatingly and then reload some cell - the reload animation will appear on top of the insertion animation.
        // Basically everytime you see any animation glitches - process batch updates in isolation.
        let requiresIsolatedProcess = chatLayout.keepContentAtBottomOfVisibleArea == true && chatLayout.collectionViewContentSize.height < chatLayout.visibleBounds.height ? true : requiresIsolatedProcess
        processUpdates(with: sections, animated: true, requiresIsolatedProcess: requiresIsolatedProcess)
    }

    private func processUpdates(with sections: [Section], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            dataSource.sections = sections
            return
        }

        guard currentInterfaceActions.options.isEmpty else {
            let reaction = SetActor<Set<InterfaceActions>, ReactionTypes>.Reaction(type: .delayedUpdate,
                                                                                   action: .onEmpty,
                                                                                   executionType: .once,
                                                                                   actionBlock: { [weak self] in
                                                                                       guard let self else {
                                                                                           return
                                                                                       }
                                                                                       processUpdates(with: sections, animated: animated, requiresIsolatedProcess: requiresIsolatedProcess, completion: completion)
                                                                                   })
            currentInterfaceActions.add(reaction: reaction)
            return
        }

        func process() {
            // If there is a big amount of changes, it is better to move that calculation out of the main thread.
            // Here is on the main thread for the simplicity.
            let changeSet = StagedChangeset(source: dataSource.sections, target: sections).flattenIfPossible()

            guard !changeSet.isEmpty else {
                completion?()
                return
            }

            if requiresIsolatedProcess {
                chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = true
                currentInterfaceActions.options.insert(.updatingCollectionInIsolation)
            }
            currentControllerActions.options.insert(.updatingCollection)
            print("\(Self.self) \(#function) pre reload")
            collectionView.reload(using: changeSet,
                                  interrupt: { changeSet in
                                      guard changeSet.sectionInserted.isEmpty else {
                                          return true
                                      }
                                      return false
                                  },
                                  onInterruptedReload: {
                                      let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                                      self.collectionView.reloadData()
                                      // We want so that user on reload appeared at the very bottom of the layout
                                      self.chatLayout.restoreContentOffset(with: positionSnapshot)
                                  },
                                  completion: { _ in
                                      print("\(Self.self) \(#function) completion\n")
                                      DispatchQueue.main.async {
                                          self.chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
                                          if requiresIsolatedProcess {
                                              self.currentInterfaceActions.options.remove(.updatingCollectionInIsolation)
                                          }
                                          completion?()
                                          self.currentControllerActions.options.remove(.updatingCollection)
                                      }
                                  },
                                  setData: { data in
                                      self.dataSource.sections = data
                                  })
        }

        if animated {
            process()
        } else {
            UIView.performWithoutAnimation {
                process()
            }
        }
    }
}

extension ChatViewController: UIGestureRecognizerDelegate {
    @objc
    private func handleRevealPan(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = gesture.view as? UICollectionView,
              !editNotifier.isEditing else {
            currentInterfaceActions.options.remove(.showingAccessory)
            return
        }

        switch gesture.state {
        case .began:
            currentInterfaceActions.options.insert(.showingAccessory)
        case .changed:
            translationX = gesture.translation(in: gesture.view).x
            currentOffset += translationX

            gesture.setTranslation(.zero, in: gesture.view)
            updateTransforms(in: collectionView)
        default:
            UIView.animate(withDuration: 0.25, animations: { () in
                self.translationX = 0
                self.currentOffset = 0
                self.updateTransforms(in: collectionView, transform: .identity)
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.showingAccessory)
            })
        }
    }

    private func updateTransforms(in collectionView: UICollectionView, transform: CGAffineTransform? = nil) {
        collectionView.indexPathsForVisibleItems.forEach {
            guard let cell = collectionView.cellForItem(at: $0) else {
                return
            }
            updateTransform(transform: transform, cell: cell, indexPath: $0)
        }
    }

    private func updateTransform(transform: CGAffineTransform?, cell: UICollectionViewCell, indexPath: IndexPath) {
        var x = currentOffset

        let maxOffset: CGFloat = -100
        x = max(x, maxOffset)
        x = min(x, 0)

        swipeNotifier.setSwipeCompletionRate(x / maxOffset)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture == panGesture {
            let translation = gesture.translation(in: gesture.view)
            return (abs(translation.x) > abs(translation.y)) && (gesture == panGesture)
        }

        return true
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    public func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        guard !currentInterfaceActions.options.contains(.sendingMessage) else {
            return
        }
        scrollToBottom()
    }

    public func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let messageText = inputBar.inputTextView.text
        currentInterfaceActions.options.insert(.sendingMessage)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
            guard let self else {
                return
            }
            guard let messageText else {
                currentInterfaceActions.options.remove(.sendingMessage)
                return
            }
            scrollToBottom(completion: {
                self.chatController.sendMessage(.text(messageText)) { sections in
                    self.currentInterfaceActions.options.remove(.sendingMessage)
                    self.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
                }
            })
        }
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
    }
}

extension ChatViewController: KeyboardListenerDelegate {
    func keyboardWillChangeFrame(info: KeyboardInfo) {
        guard !currentInterfaceActions.options.contains(.changingFrameSize),
              collectionView.contentInsetAdjustmentBehavior != .never,
              let keyboardFrame = collectionView.window?.convert(info.frameEnd, to: view),
              keyboardFrame.minY > 0,
              collectionView.convert(collectionView.bounds, to: collectionView.window).maxY > info.frameEnd.minY else {
            return
        }
        currentInterfaceActions.options.insert(.changingKeyboardFrame)
        let newBottomInset = collectionView.frame.minY + collectionView.frame.size.height - keyboardFrame.minY - collectionView.safeAreaInsets.bottom
        if newBottomInset > 0,
           collectionView.contentInset.bottom != newBottomInset {
            let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)

            // Interrupting current update animation if user starts to scroll while batchUpdate is performed.
            if currentControllerActions.options.contains(.updatingCollection) {
                UIView.performWithoutAnimation {
                    self.collectionView.performBatchUpdates({})
                }
            }

            // Blocks possible updates when keyboard is being hidden interactively
            currentInterfaceActions.options.insert(.changingContentInsets)
            UIView.animate(withDuration: info.animationDuration, animations: {
                self.collectionView.performBatchUpdates({
                    self.collectionView.contentInset.bottom = newBottomInset
                    self.collectionView.scrollIndicatorInsets.bottom = newBottomInset
                }, completion: nil)

                if let positionSnapshot, !self.isUserInitiatedScrolling {
                    self.chatLayout.restoreContentOffset(with: positionSnapshot)
                }
                if #available(iOS 13.0, *) {
                } else {
                    // When contentInset is changed programmatically IOs 13 calls invalidate context automatically.
                    // this does not happen in ios 12 so we do it manually
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.changingContentInsets)
            })
        }
    }

    func keyboardDidChangeFrame(info: KeyboardInfo) {
        guard currentInterfaceActions.options.contains(.changingKeyboardFrame) else {
            return
        }
        currentInterfaceActions.options.remove(.changingKeyboardFrame)
    }
}

extension ChatViewController: FPSCounterDelegate {
    public func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
        fpsView.customView.text = "FPS: \(fps)"
    }
}
