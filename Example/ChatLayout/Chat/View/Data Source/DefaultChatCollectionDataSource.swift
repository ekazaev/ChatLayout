//
// ChatLayout
// DefaultChatCollectionDataSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
import UIKit

typealias TextMessageCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<AvatarView, TextMessageView, StatusView>>>
@available(iOS 13, *)
typealias URLCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<AvatarView, URLView, StatusView>>>
typealias ImageCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<AvatarView, ImageView, StatusView>>>
typealias TitleCollectionCell = ContainerCollectionViewCell<UILabel>
typealias UserTitleCollectionCell = ContainerCollectionViewCell<SwappingContainerView<EdgeAligningView<UILabel>, UIImageView>>
typealias TypingIndicatorCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<AvatarPlaceholderView, TextMessageView, VoidViewFactory>>>

typealias TextTitleView = ContainerCollectionReusableView<UILabel>

final class DefaultChatCollectionDataSource: NSObject, ChatCollectionDataSource {
    private unowned var reloadDelegate: ReloadDelegate

    private unowned var editingDelegate: EditingAccessoryControllerDelegate

    private let editNotifier: EditNotifier

    private let swipeNotifier: SwipeNotifier

    var sections: [Section] = [] {
        didSet {
            oldSections = oldValue
        }
    }

    private var oldSections: [Section] = []

    init(editNotifier: EditNotifier,
         swipeNotifier: SwipeNotifier,
         reloadDelegate: ReloadDelegate,
         editingDelegate: EditingAccessoryControllerDelegate) {
        self.reloadDelegate = reloadDelegate
        self.editingDelegate = editingDelegate
        self.editNotifier = editNotifier
        self.swipeNotifier = swipeNotifier
    }

    func prepare(with collectionView: UICollectionView) {
        collectionView.register(TextMessageCollectionCell.self, forCellWithReuseIdentifier: TextMessageCollectionCell.reuseIdentifier)
        collectionView.register(ImageCollectionCell.self, forCellWithReuseIdentifier: ImageCollectionCell.reuseIdentifier)
        collectionView.register(TitleCollectionCell.self, forCellWithReuseIdentifier: TitleCollectionCell.reuseIdentifier)
        collectionView.register(UserTitleCollectionCell.self, forCellWithReuseIdentifier: UserTitleCollectionCell.reuseIdentifier)
        collectionView.register(TypingIndicatorCollectionCell.self, forCellWithReuseIdentifier: TypingIndicatorCollectionCell.reuseIdentifier)
        collectionView.register(TextTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TextTitleView.reuseIdentifier)
        collectionView.register(TextTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: TextTitleView.reuseIdentifier)
        if #available(iOS 13.0, *) {
            collectionView.register(URLCollectionCell.self, forCellWithReuseIdentifier: URLCollectionCell.reuseIdentifier)
        }
    }

    private func createTextCell(collectionView: UICollectionView, messageId: UUID, indexPath: IndexPath, text: String, date: Date, alignment: ChatItemAlignment, user: User, bubbleType: Cell.BubbleType, status: MessageStatus, messageType: MessageType) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextMessageCollectionCell.reuseIdentifier, for: indexPath) as! TextMessageCollectionCell
        setupMessageContainerView(cell.customView, messageId: messageId, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, alignment: alignment, bubble: bubbleType, status: status)

        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)

        let bubbleView = cell.customView.customView.customView
        let controller = TextMessageController(text: text,
                                               type: messageType,
                                               bubbleController: buildTextBubbleController(bubbleView: bubbleView, messageType: messageType, bubbleType: bubbleType))
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView

        return cell
    }

    @available(iOS 13, *)
    private func createURLCell(collectionView: UICollectionView, messageId: UUID, indexPath: IndexPath, url: URL, date: Date, alignment: ChatItemAlignment, user: User, bubbleType: Cell.BubbleType, status: MessageStatus, messageType: MessageType) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: URLCollectionCell.reuseIdentifier, for: indexPath) as! URLCollectionCell
        setupMessageContainerView(cell.customView, messageId: messageId, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, alignment: alignment, bubble: bubbleType, status: status)

        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)

        let bubbleView = cell.customView.customView.customView
        let controller = URLController(url: url,
                                       messageId: messageId,
                                       bubbleController: buildBezierBubbleController(for: bubbleView, messageType: messageType, bubbleType: bubbleType))

        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        controller.delegate = reloadDelegate
        cell.delegate = bubbleView.customView

        return cell
    }

    private func createImageCell(collectionView: UICollectionView, messageId: UUID, indexPath: IndexPath, alignment: ChatItemAlignment, user: User, source: ImageMessageSource, date: Date, bubbleType: Cell.BubbleType, status: MessageStatus, messageType: MessageType) -> ImageCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionCell.reuseIdentifier, for: indexPath) as! ImageCollectionCell

        setupMessageContainerView(cell.customView, messageId: messageId, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, alignment: alignment, bubble: bubbleType, status: status)

        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)

        let bubbleView = cell.customView.customView.customView
        let controller = ImageController(source: source,
                                         messageId: messageId,
                                         bubbleController: buildBezierBubbleController(for: bubbleView, messageType: messageType, bubbleType: bubbleType))

        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView

        return cell
    }

    private func createTypingIndicatorCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TypingIndicatorCollectionCell.reuseIdentifier, for: indexPath) as! TypingIndicatorCollectionCell
        let alignment = ChatItemAlignment.leading
        cell.customView.alignment = alignment
        let bubbleView = cell.customView.customView.customView
        let controller = TextMessageController(text: "Typing...",
                                               type: .incoming,
                                               bubbleController: buildTextBubbleController(bubbleView: bubbleView, messageType: .incoming, bubbleType: .tailed))
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.customView.accessoryView?.isHiddenSafe = true
        cell.delegate = bubbleView.customView

        return cell
    }

    private func createGroupTitle(collectionView: UICollectionView, indexPath: IndexPath, alignment: ChatItemAlignment, title: String) -> UserTitleCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserTitleCollectionCell.reuseIdentifier, for: indexPath) as! UserTitleCollectionCell
        cell.customView.spacing = 2

        cell.customView.customView.customView.text = title
        cell.customView.customView.customView.preferredMaxLayoutWidth = (collectionView.collectionViewLayout as? CollectionViewChatLayout)?.layoutFrame.width ?? collectionView.frame.width
        cell.customView.customView.customView.textColor = .gray
        cell.customView.customView.customView.numberOfLines = 0
        cell.customView.customView.customView.font = .preferredFont(forTextStyle: .caption2)
        cell.customView.customView.flexibleEdges = [.top]

        cell.customView.accessoryView.contentMode = .scaleAspectFit
        cell.customView.accessoryView.tintColor = .gray
        cell.customView.accessoryView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            if cell.customView.accessoryView.image == nil {
                cell.customView.accessoryView.image = UIImage(systemName: "person")
                let constraints = [
                    cell.customView.accessoryView.widthAnchor.constraint(equalTo: cell.customView.accessoryView.heightAnchor),
                    cell.customView.accessoryView.heightAnchor.constraint(equalTo: cell.customView.customView.customView.heightAnchor, constant: 2)
                ]
                constraints.forEach { $0.priority = UILayoutPriority(rawValue: 999) }
                cell.customView.customView.customView.setContentHuggingPriority(.required, for: .vertical)
                cell.customView.accessoryView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                NSLayoutConstraint.activate(constraints)
            }
        } else {
            cell.customView.accessoryView.isHidden = true
        }
        cell.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 40, bottom: 2, right: 40)
        return cell
    }

    private func createDateTitle(collectionView: UICollectionView, indexPath: IndexPath, alignment: ChatItemAlignment, title: String) -> TitleCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCollectionCell.reuseIdentifier, for: indexPath) as! TitleCollectionCell
        cell.customView.preferredMaxLayoutWidth = (collectionView.collectionViewLayout as? CollectionViewChatLayout)?.layoutFrame.width ?? collectionView.frame.width
        cell.customView.text = title
        cell.customView.textColor = .gray
        cell.customView.numberOfLines = 0
        cell.customView.font = .preferredFont(forTextStyle: .caption2)
        cell.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        return cell
    }

    private func setupMessageContainerView(_ messageContainerView: MessageContainerView<EditingAccessoryView, some Any>, messageId: UUID, alignment: ChatItemAlignment) {
        messageContainerView.alignment = alignment
        if let accessoryView = messageContainerView.accessoryView {
            editNotifier.add(delegate: accessoryView)
            accessoryView.setIsEditing(editNotifier.isEditing)

            let controller = EditingAccessoryController(messageId: messageId)
            controller.view = accessoryView
            controller.delegate = editingDelegate
            accessoryView.setup(with: controller)
        }
    }

    private func setupMainMessageView(_ cellView: MainContainerView<AvatarView, some Any, StatusView>,
                                      user: User,
                                      alignment: ChatItemAlignment,
                                      bubble: Cell.BubbleType,
                                      status: MessageStatus) {
        cellView.containerView.alignment = .bottom
        cellView.containerView.leadingView?.isHiddenSafe = !alignment.isIncoming
        cellView.containerView.leadingView?.alpha = alignment.isIncoming ? 1 : 0
        cellView.containerView.trailingView?.isHiddenSafe = alignment.isIncoming
        cellView.containerView.trailingView?.alpha = alignment.isIncoming ? 0 : 1
        cellView.containerView.trailingView?.setup(with: status)
        if let avatarView = cellView.containerView.leadingView {
            let avatarViewController = AvatarViewController(user: user, bubble: bubble)
            avatarView.setup(with: avatarViewController)
            avatarViewController.view = avatarView
            if let avatarDelegate = cellView.customView.customView as? AvatarViewDelegate {
                avatarView.delegate = avatarDelegate
            } else {
                avatarView.delegate = nil
            }
        }
    }

    private func setupSwipeHandlingAccessory(_ cellView: MainContainerView<AvatarView, some Any, StatusView>,
                                             date: Date,
                                             accessoryConnectingView: UIView) {
        cellView.accessoryConnectingView = accessoryConnectingView
        cellView.accessoryView.setup(with: DateAccessoryController(date: date))
        cellView.accessorySafeAreaInsets = swipeNotifier.accessorySafeAreaInsets
        cellView.swipeCompletionRate = swipeNotifier.swipeCompletionRate
        swipeNotifier.add(delegate: cellView)
    }

    private func buildTextBubbleController(bubbleView: BezierMaskedView<some Any>, messageType: MessageType, bubbleType: Cell.BubbleType) -> BubbleController {
        let textBubbleController = TextBubbleController(bubbleView: bubbleView, type: messageType, bubbleType: bubbleType)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: textBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }

    private func buildBezierBubbleController(for bubbleView: BezierMaskedView<some Any>, messageType: MessageType, bubbleType: Cell.BubbleType) -> BubbleController {
        let contentBubbleController = FullCellContentBubbleController(bubbleView: bubbleView)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: contentBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
}

extension DefaultChatCollectionDataSource: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].cells.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = sections[indexPath.section].cells[indexPath.item]
        switch cell {
        case let .message(message, bubbleType: bubbleType):
            switch message.data {
            case let .text(text):
                let cell = createTextCell(collectionView: collectionView, messageId: message.id, indexPath: indexPath, text: text, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                return cell
            case let .url(url, isLocallyStored: _):
                if #available(iOS 13.0, *) {
                    return createURLCell(collectionView: collectionView, messageId: message.id, indexPath: indexPath, url: url, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                } else {
                    return createTextCell(collectionView: collectionView, messageId: message.id, indexPath: indexPath, text: url.absoluteString, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                }
            case let .image(source, isLocallyStored: _):
                let cell = createImageCell(collectionView: collectionView, messageId: message.id, indexPath: indexPath, alignment: cell.alignment, user: message.owner, source: source, date: message.date, bubbleType: bubbleType, status: message.status, messageType: message.type)
                return cell
            }
        case let .messageGroup(group):
            let cell = createGroupTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, title: group.title)
            return cell
        case let .date(group):
            let cell = createDateTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, title: group.value)
            return cell
        case .typingIndicator:
            return createTypingIndicatorCell(collectionView: collectionView, indexPath: indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: TextTitleView.reuseIdentifier,
                                                                       for: indexPath) as! TextTitleView
            view.customView.text = sections[indexPath.section].title
            view.customView.preferredMaxLayoutWidth = 300
            view.customView.textColor = .lightGray
            view.customView.numberOfLines = 0
            view.customView.font = .preferredFont(forTextStyle: .caption2)
            return view
        case UICollectionView.elementKindSectionFooter:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: TextTitleView.reuseIdentifier,
                                                                       for: indexPath) as! TextTitleView
            view.customView.text = "Made with ChatLayout"
            view.customView.preferredMaxLayoutWidth = 300
            view.customView.textColor = .lightGray
            view.customView.numberOfLines = 0
            view.customView.font = .preferredFont(forTextStyle: .caption2)
            return view
        default:
            fatalError()
        }
    }
}

extension DefaultChatCollectionDataSource: ChatLayoutDelegate {
    public func shouldPresentHeader(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        true
    }

    public func shouldPresentFooter(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        true
    }

    public func sizeForItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
        switch kind {
        case .cell:
            let item = sections[indexPath.section].cells[indexPath.item]
            switch item {
            case let .message(message, bubbleType: _):
                switch message.data {
// Uncomment to test exact sizes
//                case let .text(text):
//                    let rect = (text as NSString).boundingRect(with: .init(width: chatLayout.layoutFrame.width * Constants.maxWidth, height: CGFloat.greatestFiniteMagnitude),options: [NSStringDrawingOptions.usesLineFragmentOrigin, NSStringDrawingOptions.usesFontLeading] , attributes: [.font: UIFont.preferredFont(forTextStyle: .body)], context: nil)
//                    return .exact(CGSize(width: chatLayout.layoutFrame.width, height: rect.height + 16))

                case .text:
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 36))
                case let .image(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 120 : 80))
                case let .url(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 60 : 36))
                }
            case .date:
                return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 18))
            case .typingIndicator:
                return .estimated(CGSize(width: 60, height: 36))
            case .messageGroup:
                return .estimated(CGSize(width: min(85, chatLayout.layoutFrame.width / 3), height: 18))
            }
        case .footer,
             .header:
            return .auto
        }
    }

    public func alignmentForItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment {
        switch kind {
        case .header:
            return .center
        case .cell:
            let item = sections[indexPath.section].cells[indexPath.item]
            switch item {
            case .date:
                return .center
            case .message:
                return .fullWidth
            case .messageGroup,
                 .typingIndicator:
                return .leading
            }
        case .footer:
            return .trailing
        }
    }

    public func initialLayoutAttributesForInsertedItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath, modifying originalAttributes: ChatLayoutAttributes, on state: InitialAttributesRequestType) {
        originalAttributes.alpha = 0
        guard state == .invalidation,
              kind == .cell else {
            return
        }
        switch sections[indexPath.section].cells[indexPath.item] {
        // Uncomment to see the effect
//        case .messageGroup:
//            originalAttributes.center.x -= originalAttributes.frame.width
//        case let .message(message, bubbleType: _):
//            originalAttributes.transform = .init(scaleX: 0.9, y: 0.9)
//            originalAttributes.transform = originalAttributes.transform.concatenating(.init(rotationAngle: message.type == .incoming ? -0.05 : 0.05))
//            originalAttributes.center.x += (message.type == .incoming ? -20 : 20)
        case .typingIndicator:
            originalAttributes.transform = .init(scaleX: 0.1, y: 0.1)
            originalAttributes.center.x -= originalAttributes.bounds.width / 5
        default:
            break
        }
    }

    public func finalLayoutAttributesForDeletedItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath, modifying originalAttributes: ChatLayoutAttributes) {
        originalAttributes.alpha = 0
        guard kind == .cell else {
            return
        }
        switch oldSections[indexPath.section].cells[indexPath.item] {
        // Uncomment to see the effect
//        case .messageGroup:
//            originalAttributes.center.x -= originalAttributes.frame.width
//        case let .message(message, bubbleType: _):
//            originalAttributes.transform = .init(scaleX: 0.9, y: 0.9)
//            originalAttributes.transform = originalAttributes.transform.concatenating(.init(rotationAngle: message.type == .incoming ? -0.05 : 0.05))
//            originalAttributes.center.x += (message.type == .incoming ? -20 : 20)
        case .typingIndicator:
            originalAttributes.transform = .init(scaleX: 0.1, y: 0.1)
            originalAttributes.center.x -= originalAttributes.bounds.width / 5
        default:
            break
        }
    }

    public func interItemSpacing(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, after indexPath: IndexPath) -> CGFloat? {
        let item = sections[indexPath.section].cells[indexPath.item]
        switch item {
        case .messageGroup:
            return 3
        default:
            return nil
        }
    }

    public func interSectionSpacing(_ chatLayout: CollectionViewChatLayout, after sectionIndex: Int) -> CGFloat? {
        50
    }
}
