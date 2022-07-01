//
// ChatLayout
// ChatViewController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import ChatLayout
import DifferenceKit
import Foundation
import FPSCounter
import InputBarAccessoryView
import UIKit

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
    }

    private enum ControllerActions {
        case loadingInitialMessages
        case loadingPreviousMessages
        case updatingCollection
    }

    override var inputAccessoryView: UIView? {
        return inputBarView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()
    private let editNotifier: EditNotifier
    private let swipeNotifier: SwipeNotifier
    private var collectionView: UICollectionView!
    private var chatLayout = ChatLayout()
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

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: chatLayout)
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

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.frame = view.bounds
        collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        dataSource.prepare(with: collectionView)

        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { sections in
            self.currentControllerActions.options.remove(.loadingInitialMessages)
            self.processUpdates(with: sections, animated: true)
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
            if let positionSnapshot = positionSnapshot,
               !self.isUserInitiatedScrolling {
                // As contentInsets may change when size transition has already started. For example, `UINavigationBar` height may change
                // to compact and back. `ChatLayout` may not properly predict the final position of the element. So we try
                // to restore it after the rotation manually.
                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.currentInterfaceActions.options.remove(.changingFrameSize)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }

    @objc private func showHideKeyboard() {
        if inputBarView.inputTextView.isFirstResponder {
            navigationItem.leftBarButtonItem?.title = "Show Keyboard"
            inputBarView.inputTextView.resignFirstResponder()
        } else {
            navigationItem.leftBarButtonItem?.title = "Hide Keyboard"
            inputBarView.inputTextView.becomeFirstResponder()
        }
    }

    @objc private func setEditNotEdit() {
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
            guard let self = self else {
                return
            }
            // Reloading the content without animation just because it looks better is the scrolling is in process.
            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: animated) {
                self.currentControllerActions.options.remove(.loadingPreviousMessages)
            }
        }
    }

    fileprivate var isUserInitiatedScrolling: Bool {
        return collectionView.isDragging || collectionView.isDecelerating
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
                guard let self = self else {
                    return
                }
                self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: initialOffset + (delta * percentage))
                if percentage == 1.0 {
                    self.animator = nil
                    let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .footer, edge: .bottom)
                    self.chatLayout.restoreContentOffset(with: positionSnapshot)
                    self.currentInterfaceActions.options.remove(.scrollingToBottom)
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
        return preview(for: configuration)
    }

    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return preview(for: configuration)
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
                return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: { _ in return menu })
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

    func update(with sections: [Section]) {
        processUpdates(with: sections, animated: true)
    }

    private func processUpdates(with sections: [Section], animated: Bool = true, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            dataSource.sections = sections
            return
        }

        guard currentInterfaceActions.options.isEmpty else {
            let reaction = SetActor<Set<InterfaceActions>, ReactionTypes>.Reaction(type: .delayedUpdate,
                                                                                   action: .onEmpty,
                                                                                   executionType: .once,
                                                                                   actionBlock: { [weak self] in
                                                                                       guard let self = self else {
                                                                                           return
                                                                                       }
                                                                                       self.processUpdates(with: sections, animated: animated, completion: completion)
                                                                                   })
            currentInterfaceActions.add(reaction: reaction)
            return
        }

        func process() {
            // If there is a big amount of changes, it is better to move that calculation out of the main thread.
            // Here is on the main thread for the simplicity.
            let changeSet = StagedChangeset(source: dataSource.sections, target: sections).flattenIfPossible()

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

    @objc private func handleRevealPan(_ gesture: UIPanGestureRecognizer) {
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
            guard let cell = collectionView.cellForItem(at: $0) else { return }
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
        return [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
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
            guard let self = self else {
                return
            }
            guard let messageText = messageText else {
                self.currentInterfaceActions.options.remove(.sendingMessage)
                return
            }
            self.scrollToBottom(completion: {
                self.chatController.sendMessage(.text(messageText)) { sections in
                    self.currentInterfaceActions.options.remove(.sendingMessage)
                    self.processUpdates(with: sections, animated: true)
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

            // Blocks possible updates when keyboard is being hidden interactively
            currentInterfaceActions.options.insert(.changingContentInsets)
            UIView.animate(withDuration: info.animationDuration, animations: {
                self.collectionView.performBatchUpdates({
                    self.collectionView.contentInset.bottom = newBottomInset
                    self.collectionView.scrollIndicatorInsets.bottom = newBottomInset
                }, completion: nil)

                if let positionSnapshot = positionSnapshot, !self.isUserInitiatedScrolling {
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
