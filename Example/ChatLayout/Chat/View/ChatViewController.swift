//
// ChatLayout
// ChatViewController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
import FPSCounter
import InputBarAccessoryView
import UIKit

/// It's advisable to continue using the reload/reconfigure method, especially when multiple changes occur concurrently in an animated fashion.
/// This approach ensures that the ChatLayout can handle these changes while maintaining the content offset accurately.
/// Consider using it when no better alternatives are available.
let enableSelfSizingSupport = false

/// By setting this flag to true you can test reconfigure instead of reload.
let enableReconfigure = true

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

    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()
    private let editNotifier: EditNotifier
    private let swipeNotifier: SwipeNotifier
    private var collectionView: UICollectionView!
    private var chatLayout = CollectionViewChatLayout()
    private let inputBarView = InputBarAccessoryView()
    private let chatController: ChatController
    private let layoutDataSource: ChatCollectionDataSource
    private let fpsCounter = FPSCounter()
    private let fpsView = EdgeAligningView<UILabel>(frame: CGRect(origin: .zero, size: .init(width: 30, height: 30)))
    private var animator: ManualAnimator?
    private var activeCollectionUpdates = 0
    private var needsScrollToBottomOnAppearance = false
    private var cellsByID: [Cell.ID: Cell] = [:]
    private lazy var editBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(ChatViewController.setEditNotEdit))
    private lazy var agentBarButtonItem = UIBarButtonItem(title: "Agent", style: .plain, target: self, action: #selector(ChatViewController.toggleAgentMode))
    private var shouldStartAgentAnswerAfterNextUpdate = false

    private lazy var dataSource = ChatLayoutDiffableDataSource<Int, Cell.ID>(
        collectionView: collectionView,
        cellProvider: { [weak self] collectionView, indexPath, id in
            guard let self,
                  let cell = cellsByID[id] else {
                return nil
            }
            return layoutDataSource.collectionView(collectionView, cellFor: cell, at: indexPath)
        }
    )

    private var translationX: CGFloat = 0
    private var currentOffset: CGFloat = 0

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleRevealPan(_:)))
        gesture.delegate = self
        return gesture
    }()

    init(
        chatController: ChatController,
        dataSource: ChatCollectionDataSource,
        editNotifier: EditNotifier,
        swipeNotifier: SwipeNotifier
    ) {
        self.chatController = chatController
        layoutDataSource = dataSource
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
        view.backgroundColor = .systemBackground

        inputBarView.delegate = self

        fpsView.translatesAutoresizingMaskIntoConstraints = false
        fpsView.flexibleEdges = [.trailing]
        fpsView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16)
        fpsView.customView.font = .preferredFont(forTextStyle: .caption2)
        fpsView.customView.text = "FPS: unknown"
        fpsView.backgroundColor = .systemBackground
        fpsView.customView.textColor = .systemGray3
        inputBarView.topStackView.addArrangedSubview(fpsView)
        inputBarView.shouldAnimateTextDidChangeLayout = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Show Keyboard", style: .plain, target: self, action: #selector(ChatViewController.showHideKeyboard))
        navigationItem.rightBarButtonItems = [editBarButtonItem, agentBarButtonItem]
        syncAgentModeUI()

        chatLayout.settings.interItemSpacing = 8
        chatLayout.settings.interSectionSpacing = 8
        chatLayout.settings.additionalInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
        chatLayout.keepContentAtBottomOfVisibleArea = true

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: chatLayout)
        view.addSubview(collectionView)
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = dataSource
        chatLayout.delegate = layoutDataSource
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive

        // https://openradar.appspot.com/40926834
        collectionView.isPrefetchingEnabled = false

        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.automaticallyAdjustsScrollIndicatorInsets = true

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
        inputBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBarView)
        NSLayoutConstraint.activate([
            inputBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])

        layoutDataSource.prepare(with: collectionView)

        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { sections in
            self.processUpdates(with: sections, animated: false, requiresIsolatedProcess: false) {
                self.currentControllerActions.options.remove(.loadingInitialMessages)
            }
        }

        KeyboardListener.shared.add(delegate: self)
        collectionView.addGestureRecognizer(panGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard isViewLoaded else {
            return
        }
        currentInterfaceActions.options.insert(.changingFrameSize)
        let positionSnapshot = contentOffsetSnapshotForCurrentLayout()
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
        editBarButtonItem.title = isEditing ? "Done" : "Edit"
        chatLayout.invalidateLayout()
    }

    @objc
    private func toggleAgentMode() {
        let shouldEnableAgentMode = !chatController.isAgentModeEnabled
        shouldStartAgentAnswerAfterNextUpdate = shouldEnableAgentMode
        chatController.setAgentModeEnabled(shouldEnableAgentMode)
        syncAgentModeUI()
        chatLayout.invalidateLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        swipeNotifier.setAccessoryOffset(UIEdgeInsets(
            top: view.safeAreaInsets.top,
            left: view.safeAreaInsets.left + chatLayout.settings.additionalInsets.left,
            bottom: view.safeAreaInsets.bottom,
            right: view.safeAreaInsets.right + chatLayout.settings.additionalInsets.right
        ))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateComposerInsets()
        if needsScrollToBottomOnAppearance, view.window != nil {
            needsScrollToBottomOnAppearance = false
            UIView.performWithoutAnimation {
                self.restoreContentOffsetToBottom(in: self.layoutDataSource.sections)
            }
        }
    }

    private func updateComposerInsets() {
        guard !currentInterfaceActions.options.contains(.changingContentInsets) else {
            return
        }

        let composerFrame = inputBarView.convert(inputBarView.bounds, to: collectionView)
        let overlap = max(0, collectionView.bounds.maxY - composerFrame.minY)
        let bottomInset = max(0, overlap - collectionView.safeAreaInsets.bottom)
        guard collectionView.contentInset.bottom != bottomInset else {
            return
        }

        currentInterfaceActions.options.insert(.changingContentInsets)
        defer { currentInterfaceActions.options.remove(.changingContentInsets) }
        let positionSnapshot = contentOffsetSnapshotForCurrentLayout()

        if currentControllerActions.options.contains(.updatingCollection) {
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates({})
            }
        }

        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        if let positionSnapshot, !isUserInitiatedScrolling {
            chatLayout.restoreContentOffset(with: positionSnapshot)
        }
    }
}

@MainActor
extension ChatViewController: UIScrollViewDelegate {
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
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

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
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
        // Blocking the potential multiple call of that function as during the content invalidation the contentOffset of the UICollectionView can change
        // in any way so it may trigger another call of that function and lead to unexpected behaviour/animation
        currentControllerActions.options.insert(.loadingPreviousMessages)
        chatController.loadPreviousMessages { [weak self] sections in
            guard let self else {
                return
            }
            // Reloading the content without animation just because it looks better is the scrolling is in process.
            let animated = !isUserInitiatedScrolling
            processUpdates(with: sections, animated: animated, requiresIsolatedProcess: false) {
                self.currentControllerActions.options.remove(.loadingPreviousMessages)
            }
        }
    }

    fileprivate var isUserInitiatedScrolling: Bool {
        collectionView.isDragging || collectionView.isDecelerating
    }

    func scrollToBottom(completion: (() -> Void)? = nil) {
        // I ask content size from the layout because on IOs 12 collection view contains not updated one
        let contentOffsetAtBottom = CGPoint(
            x: collectionView.contentOffset.x,
            y: chatLayout.collectionViewContentSize.height - collectionView.bounds.height + collectionView.adjustedContentInset.bottom
        )

        guard contentOffsetAtBottom.y > collectionView.contentOffset.y else {
            completion?()
            return
        }

        let initialOffset = collectionView.contentOffset.y
        let delta = contentOffsetAtBottom.y - initialOffset
        currentInterfaceActions.options.insert(.scrollingToBottom)
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
                    if let lastSection = layoutDataSource.sections.last, !lastSection.cells.isEmpty {
                        let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: lastSection.cells.count - 1, section: layoutDataSource.sections.count - 1), edge: .bottom)
                        chatLayout.restoreContentOffset(with: positionSnapshot)
                    }
                    currentInterfaceActions.options.remove(.scrollingToBottom)
                    completion?()
                }
            }
        } else {
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                self?.currentInterfaceActions.options.remove(.scrollingToBottom)
                completion?()
            }
            collectionView.setContentOffset(contentOffsetAtBottom, animated: true)
            CATransaction.commit()
        }
    }
}

@MainActor
extension ChatViewController: UICollectionViewDelegate {
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

        let item = layoutDataSource.sections[0].cells[itemIndex]
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

                return UITargetedPreview(
                    view: cell.customView.customView.customView,
                    parameters: parameters,
                    target: UIPreviewTarget(container: cell.customView.customView, center: center)
                )
            default:
                return nil
            }
        default:
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        preview(for: configuration)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        preview(for: configuration)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !currentInterfaceActions.options.contains(.showingPreview),
              !currentControllerActions.options.contains(.updatingCollection) else {
            return nil
        }
        let item = layoutDataSource.sections[indexPath.section].cells[indexPath.item]
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

    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        animator?.addCompletion {
            self.currentInterfaceActions.options.remove(.showingPreview)
        }
    }
}

@MainActor
extension ChatViewController: ChatControllerDelegate {
    func update(with sections: [Section], requiresIsolatedProcess: Bool) {
        syncAgentModeUI()
        chatLayout.settings.indexPathForExtendedLayout = indexPathForExtendedLayout(in: sections)
        let shouldStartAgentAnswerAfterUpdate = shouldStartAgentAnswerAfterNextUpdate &&
            chatController.isAgentModeEnabled &&
            chatController.extendedLayoutMessageID != nil
        // if `chatLayout.keepContentAtBottomOfVisibleArea` is enabled and content size is actually smaller than the visible size - it is better to process each batch update
        // in isolation. Example: If you insert a cell animatingly and then reload some cell - the reload animation will appear on top of the insertion animation.
        // Basically everytime you see any animation glitches - process batch updates in isolation.
        let requiresIsolatedProcess = chatLayout.keepContentAtBottomOfVisibleArea == true && chatLayout.collectionViewContentSize.height < chatLayout.visibleBounds.height ? true : requiresIsolatedProcess
        processUpdates(with: sections, animated: true, requiresIsolatedProcess: requiresIsolatedProcess) {
            guard shouldStartAgentAnswerAfterUpdate else {
                return
            }
            self.shouldStartAgentAnswerAfterNextUpdate = false
            guard self.chatController.isAgentModeEnabled else {
                return
            }
            self.scrollToBottom {
                guard self.chatController.isAgentModeEnabled else {
                    return
                }
                self.chatController.startAgentResponse()
            }
        }
    }

    func agentModeChanged(to isEnabled: Bool) {
        syncAgentModeUI()
        if !isEnabled {
            shouldStartAgentAnswerAfterNextUpdate = false
            chatLayout.settings.indexPathForExtendedLayout = nil
        }
    }

    private func processUpdates(with sections: [Section], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            layoutDataSource.sections = sections
            cellsByID = sections
                .flatMap(\.cells)
                .reduce(into: [Cell.ID: Cell]()) { $0[$1.id] = $1 }
            completion?()
            return
        }

        guard currentInterfaceActions.options.isEmpty else {
            let reaction = SetActor<Set<InterfaceActions>, ReactionTypes>.Reaction(
                type: .delayedUpdate,
                action: .onEmpty,
                executionType: .once,
                actionBlock: { [weak self] in
                    guard let self else {
                        return
                    }
                    processUpdates(with: sections, animated: animated, requiresIsolatedProcess: requiresIsolatedProcess, completion: completion)
                }
            )
            currentInterfaceActions.add(reaction: reaction)
            return
        }

        performUpdates(
            with: sections,
            animated: animated,
            requiresIsolatedProcess: requiresIsolatedProcess,
            completion: completion
        )
    }

    private func performUpdates(with sections: [Section], animated: Bool, requiresIsolatedProcess: Bool, completion: (() -> Void)?) {
        guard layoutDataSource.sections != sections else {
            completion?()
            return
        }

        if dataSource.snapshot == nil || collectionView.window == nil {
            needsScrollToBottomOnAppearance = collectionView.window == nil
            UIView.performWithoutAnimation {
                self.dataSource.applySnapshotUsingReloadData(self.makeSnapshot(for: sections)) {
                    self.layoutDataSource.sections = sections
                    self.cellsByID = sections.flatMap(\.cells).reduce(into: [Cell.ID: Cell]()) { $0[$1.id] = $1 }
                }
                self.view.layoutIfNeeded()
                self.restoreContentOffsetToBottom(in: sections)
            }
            completion?()
            return
        }

        let oldCells = layoutDataSource.sections
            .flatMap(\.cells)
            .reduce(into: [Cell.ID: Cell]()) { $0[$1.id] = $1 }
        let newCells = sections.flatMap(\.cells)
        let newCellsByID = newCells.reduce(into: [Cell.ID: Cell]()) { $0[$1.id] = $1 }
        var snapshot = makeSnapshot(for: sections)
        var reconfiguredCellIDs: [Cell.ID] = []
        var reloadedCellIDs: [Cell.ID] = []
        for cell in newCells {
            guard let oldCell = oldCells[cell.id], oldCell != cell else {
                continue
            }

            var usesSameCellType = true
            if case let .message(oldMessage, _) = oldCell,
               case let .message(newMessage, _) = cell {
                switch (oldMessage.data, newMessage.data) {
                case (.image, .image),
                     (.text, .text),
                     (.url, .url):
                    break
                default:
                    usesSameCellType = false
                }
            }

            if enableReconfigure, usesSameCellType {
                reconfiguredCellIDs.append(cell.id)
            } else {
                reloadedCellIDs.append(cell.id)
            }
        }
        snapshot.reconfigureItems(reconfiguredCellIDs)
        snapshot.reloadItems(reloadedCellIDs)

        if requiresIsolatedProcess {
            chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = true
            currentInterfaceActions.options.insert(.updatingCollectionInIsolation)
        }
        activeCollectionUpdates += 1
        currentControllerActions.options.insert(.updatingCollection)

        dataSource.apply(snapshot, animatingDifferences: animated, commitAlongsideUpdates: {
            self.layoutDataSource.sections = sections
            self.cellsByID = newCellsByID
        }, completion: {
            DispatchQueue.main.async {
                self.collectionView.setNeedsLayout()
                self.collectionView.layoutIfNeeded()

                if requiresIsolatedProcess {
                    self.chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
                    self.currentInterfaceActions.options.remove(.updatingCollectionInIsolation)
                }
                completion?()
                self.activeCollectionUpdates -= 1
                if self.activeCollectionUpdates == 0 {
                    self.currentControllerActions.options.remove(.updatingCollection)
                }
            }
        })
    }

    private func makeSnapshot(for sections: [Section]) -> NSDiffableDataSourceSnapshot<Int, Cell.ID> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Cell.ID>()
        for section in sections {
            snapshot.appendSections([section.id])
            snapshot.appendItems(section.cells.map(\.id), toSection: section.id)
        }
        return snapshot
    }

    private func restoreContentOffsetToBottom(in sections: [Section]) {
        guard let lastSection = sections.last,
              !lastSection.cells.isEmpty else {
            return
        }
        collectionView.layoutIfNeeded()
        let positionSnapshot = ChatLayoutPositionSnapshot(
            indexPath: IndexPath(item: lastSection.cells.count - 1, section: sections.count - 1),
            edge: .bottom
        )
        chatLayout.restoreContentOffset(with: positionSnapshot)
    }
}

@MainActor
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

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture == panGesture {
            let translation = gesture.translation(in: gesture.view)
            return (abs(translation.x) > abs(translation.y)) && (gesture == panGesture)
        }

        return true
    }
}

extension ChatViewController: @MainActor InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        view.setNeedsLayout()
    }

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
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
        currentInterfaceActions.options.insert(.changingKeyboardFrame)
    }

    func keyboardDidChangeFrame(info: KeyboardInfo) {
        view.layoutIfNeeded()
        currentInterfaceActions.options.remove(.changingKeyboardFrame)
    }
}

@MainActor
private extension ChatViewController {
    func syncAgentModeUI() {
        agentBarButtonItem.title = chatController.isAgentModeEnabled ? "Agent Off" : "Agent"
    }

    func indexPathForExtendedLayout(in sections: [Section]) -> IndexPath? {
        guard chatController.isAgentModeEnabled,
              let extendedLayoutMessageID = chatController.extendedLayoutMessageID else {
            return nil
        }

        for (sectionIndex, section) in sections.enumerated() {
            for (itemIndex, cell) in section.cells.enumerated() {
                guard case let .message(message, bubbleType: _) = cell,
                      message.id == extendedLayoutMessageID else {
                    continue
                }
                return IndexPath(item: itemIndex, section: sectionIndex)
            }
        }

        return nil
    }

    func contentOffsetSnapshotForCurrentLayout() -> ChatLayoutPositionSnapshot? {
        if chatLayout.settings.indexPathForExtendedLayout != nil {
            return chatLayout.getContentOffsetSnapshot(from: .top)
        } else {
            return chatLayout.getContentOffsetSnapshot(from: .bottom)
        }
    }
}

extension ChatViewController: @MainActor FPSCounterDelegate {
    func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
        fpsView.customView.text = "FPS: \(fps)"
    }
}

