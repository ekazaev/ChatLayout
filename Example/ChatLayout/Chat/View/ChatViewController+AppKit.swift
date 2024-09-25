//
//  ChatViewController+AppKit.swift
//  ChatLayout
//
//  Created by JH on 2024/9/25.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import ChatLayout
import DifferenceKit

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

final class ChatViewController: NSViewController {
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

    override var acceptsFirstResponder: Bool { true }

    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()
    private let editNotifier: EditNotifier
    private let swipeNotifier: SwipeNotifier
    private var collectionView: NSCollectionView!
    private var scrollView: NSScrollView!
    private var chatLayout = CollectionViewChatLayout()
    private let chatController: ChatController
    private let dataSource: ChatCollectionDataSource
    private var animator: ManualAnimator?

    private var translationX: CGFloat = 0
    private var currentOffset: CGFloat = 0

    private lazy var panGesture: NSPanGestureRecognizer = {
        let gesture = NSPanGestureRecognizer(target: self, action: #selector(handleRevealPan(_:)))
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
        chatLayout.settings.interItemSpacing = 8
        chatLayout.settings.interSectionSpacing = 8
        chatLayout.settings.additionalInsets = NSEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
        chatLayout.keepContentAtBottomOfVisibleArea = true

        scrollView = NSScrollView()
        collectionView = NSCollectionView(frame: view.frame)
        collectionView.collectionViewLayout = chatLayout
        view.addSubview(scrollView)
        scrollView.documentView = collectionView
        collectionView.dataSource = dataSource
        chatLayout.delegate = dataSource
        collectionView.delegate = self

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.frame = view.bounds
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        dataSource.prepare(with: collectionView)

        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { sections in
            self.currentControllerActions.options.remove(.loadingInitialMessages)
            self.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
        }

        collectionView.addGestureRecognizer(panGesture)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        collectionView.collectionViewLayout?.invalidateLayout()
    }

//    @objc
//    private func setEditNotEdit() {
//        isEditing = !isEditing
//        editNotifier.setIsEditing(isEditing, duration: .animated(duration: 0.25))
//        navigationItem.rightBarButtonItem?.title = isEditing ? "Done" : "Edit"
//        chatLayout.invalidateLayout()
//    }

//    override func viewSafeAreaInsetsDidChange() {
//        super.viewSafeAreaInsetsDidChange()
//        swipeNotifier.setAccessoryOffset(UIEdgeInsets(top: view.safeAreaInsets.top,
//                                                      left: view.safeAreaInsets.left + chatLayout.settings.additionalInsets.left,
//                                                      bottom: view.safeAreaInsets.bottom,
//                                                      right: view.safeAreaInsets.right + chatLayout.settings.additionalInsets.right))
//    }

}

//extension ChatViewController: UIScrollViewDelegate {
//    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
//        guard scrollView.contentSize.height > 0,
//              !currentInterfaceActions.options.contains(.showingAccessory),
//              !currentInterfaceActions.options.contains(.showingPreview),
//              !currentInterfaceActions.options.contains(.scrollingToTop),
//              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
//            return false
//        }
//        // Blocking the call of loadPreviousMessages() as UIScrollView behaves the way that it will scroll to the top even if we keep adding
//        // content there and keep changing the content offset until it actually reaches the top. So instead we wait until it reaches the top and initiate
//        // the loading after.
//        currentInterfaceActions.options.insert(.scrollingToTop)
//        return true
//    }
//
//    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
//        guard !currentControllerActions.options.contains(.loadingInitialMessages),
//              !currentControllerActions.options.contains(.loadingPreviousMessages) else {
//            return
//        }
//        currentInterfaceActions.options.remove(.scrollingToTop)
//        loadPreviousMessages()
//    }
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if currentControllerActions.options.contains(.updatingCollection), collectionView.isDragging {
//            // Interrupting current update animation if user starts to scroll while batchUpdate is performed. It helps to
//            // avoid presenting blank area if user scrolls out of the animation rendering area.
//            UIView.performWithoutAnimation {
//                self.collectionView.performBatchUpdates({}, completion: { _ in
//                    let context = ChatLayoutInvalidationContext()
//                    context.invalidateLayoutMetrics = false
//                    self.collectionView.collectionViewLayout.invalidateLayout(with: context)
//                })
//            }
//        }
//        guard !currentControllerActions.options.contains(.loadingInitialMessages),
//              !currentControllerActions.options.contains(.loadingPreviousMessages),
//              !currentInterfaceActions.options.contains(.scrollingToTop),
//              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
//            return
//        }
//
//        if scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + scrollView.bounds.height {
//            loadPreviousMessages()
//        }
//    }
//
//    private func loadPreviousMessages() {
//        // Blocking the potential multiple call of that function as during the content invalidation the contentOffset of the UICollectionView can change
//        // in any way so it may trigger another call of that function and lead to unexpected behaviour/animation
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
//    }
//
//    fileprivate var isUserInitiatedScrolling: Bool {
//        collectionView.isDragging || collectionView.isDecelerating
//    }
//
//    func scrollToBottom(completion: (() -> Void)? = nil) {
//        // I ask content size from the layout because on IOs 12 collection view contains not updated one
//        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
//                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)
//
//        guard contentOffsetAtBottom.y > collectionView.contentOffset.y else {
//            completion?()
//            return
//        }
//
//        let initialOffset = collectionView.contentOffset.y
//        let delta = contentOffsetAtBottom.y - initialOffset
//        if abs(delta) > chatLayout.visibleBounds.height {
//            // See: https://dasdom.dev/posts/scrolling-a-collection-view-with-custom-duration/
//            animator = ManualAnimator()
//            animator?.animate(duration: TimeInterval(0.25), curve: .easeInOut) { [weak self] percentage in
//                guard let self else {
//                    return
//                }
//                collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: initialOffset + (delta * percentage))
//                if percentage == 1.0 {
//                    animator = nil
//                    let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .footer, edge: .bottom)
//                    chatLayout.restoreContentOffset(with: positionSnapshot)
//                    currentInterfaceActions.options.remove(.scrollingToBottom)
//                    completion?()
//                }
//            }
//        } else {
//            currentInterfaceActions.options.insert(.scrollingToBottom)
//            UIView.animate(withDuration: 0.25, animations: { [weak self] in
//                self?.collectionView.setContentOffset(contentOffsetAtBottom, animated: true)
//            }, completion: { [weak self] _ in
//                self?.currentInterfaceActions.options.remove(.scrollingToBottom)
//                completion?()
//            })
//        }
//    }
//}
//
extension ChatViewController: NSCollectionViewDelegate {
//    @available(iOS 13.0, *)
//    private func preview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        guard let identifier = configuration.identifier as? String else {
//            return nil
//        }
//        let components = identifier.split(separator: "|")
//        guard components.count == 2,
//              let sectionIndex = Int(components[0]),
//              let itemIndex = Int(components[1]),
//              let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: sectionIndex)) as? TextMessageCollectionCell else {
//            return nil
//        }
//
//        let item = dataSource.sections[0].cells[itemIndex]
//        switch item {
//        case let .message(message, bubbleType: _):
//            switch message.data {
//            case .text:
//                let parameters = UIPreviewParameters()
//                // `UITargetedPreview` doesnt support image mask (Why?) like the one I use to mask the message bubble in the example app.
//                // So I replaced default `ImageMaskedView` with `BezierMaskedView` that can uses `UIBezierPath` to mask the message view
//                // instead. So we are reusing that path here.
//                //
//                // NB: This way of creating the preview is not valid for long texts as `UITextView` within message view uses `CATiledLayer`
//                // to render its content, so it may not render itself fully when it is partly outside the collection view. You will have to
//                // recreate a brand new view that will behave as a preview. It is outside of the scope of the example app.
//                parameters.visiblePath = cell.customView.customView.customView.maskingPath
//                var center = cell.customView.customView.customView.center
//                center.x += (message.type.isIncoming ? cell.customView.customView.customView.offset : -cell.customView.customView.customView.offset) / 2
//
//                return UITargetedPreview(view: cell.customView.customView.customView,
//                                         parameters: parameters,
//                                         target: UIPreviewTarget(container: cell.customView.customView, center: center))
//            default:
//                return nil
//            }
//        default:
//            return nil
//        }
//    }
//
//    @available(iOS 13.0, *)
//    public func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        preview(for: configuration)
//    }
//
//    @available(iOS 13.0, *)
//    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        preview(for: configuration)
//    }
//
//    @available(iOS 13.0, *)
//    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        guard !currentInterfaceActions.options.contains(.showingPreview),
//              !currentControllerActions.options.contains(.updatingCollection) else {
//            return nil
//        }
//        let item = dataSource.sections[indexPath.section].cells[indexPath.item]
//        switch item {
//        case let .message(message, bubbleType: _):
//            switch message.data {
//            case let .text(body):
//                let actions = [UIAction(title: "Copy", image: nil, identifier: nil) { [body] _ in
//                    let pasteboard = UIPasteboard.general
//                    pasteboard.string = body
//                }]
//                let menu = UIMenu(title: "", children: actions)
//                // Custom NSCopying identifier leads to the crash. No other requirements for the identifier to avoid the crash are provided.
//                let identifier: NSString = "\(indexPath.section)|\(indexPath.item)" as NSString
//                currentInterfaceActions.options.insert(.showingPreview)
//                return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: { _ in menu })
//            default:
//                return nil
//            }
//        default:
//            return nil
//        }
//    }
//
//    @available(iOS 13.2, *)
//    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
//        animator?.addCompletion {
//            self.currentInterfaceActions.options.remove(.showingPreview)
//        }
//    }
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
            NSView.performWithoutAnimation {
                process()
            }
        }
    }
}

extension ChatViewController: NSGestureRecognizerDelegate {
    @objc
    private func handleRevealPan(_ gesture: NSPanGestureRecognizer) {
        guard let collectionView = gesture.view as? NSCollectionView,
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
            NSView.animate(withDuration: 0.25, animations: { () in
                self.translationX = 0
                self.currentOffset = 0
                self.updateTransforms(in: collectionView, transform: .identity)
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.showingAccessory)
            })
        }
    }

    private func updateTransforms(in collectionView: NSCollectionView, transform: CGAffineTransform? = nil) {
        collectionView.indexPathsForVisibleItems().forEach {
            guard let cell = collectionView.item(at: $0) else {
                return
            }
            updateTransform(transform: transform, cell: cell, indexPath: $0)
        }
    }

    private func updateTransform(transform: CGAffineTransform?, cell: NSUICollectionViewCell, indexPath: IndexPath) {
        var x = currentOffset

        let maxOffset: CGFloat = -100
        x = max(x, maxOffset)
        x = min(x, 0)

        swipeNotifier.setSwipeCompletionRate(x / maxOffset)
    }

    public func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: NSGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? NSPanGestureRecognizer, gesture == panGesture {
            let translation = gesture.translation(in: gesture.view)
            return (abs(translation.x) > abs(translation.y)) && (gesture == panGesture)
        }

        return true
    }
}

#endif
