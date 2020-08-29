//
// ChatLayout
// AttachmentManager.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

open class AttachmentManager: NSObject, InputPlugin {

    public enum Attachment {
        case image(UIImage)
        case url(URL)
        case data(Data)

        @available(*, deprecated, message: ".other(AnyObject) has been depricated as of 2.0.0")
        case other(AnyObject)
    }

    // MARK: - Properties [Public]

    /// A protocol that can recieve notifications from the `AttachmentManager`
    open weak var delegate: AttachmentManagerDelegate?

    /// A protocol to passes data to the `AttachmentManager`
    open weak var dataSource: AttachmentManagerDataSource?

    open lazy var attachmentView: AttachmentCollectionView = { [weak self] in
        let attachmentView = AttachmentCollectionView()
        attachmentView.dataSource = self
        attachmentView.delegate = self
        return attachmentView
    }()

    /// The attachments that the managers holds
    public private(set) var attachments = [Attachment]() { didSet { reloadData() } }

    /// A flag you can use to determine if you want the manager to be always visible
    open var isPersistent = false { didSet { attachmentView.reloadData() } }

    /// A flag to determine if the AddAttachmentCell is visible
    open var showAddAttachmentCell = true { didSet { attachmentView.reloadData() } }

    /// The color applied to the backgroundColor of the deleteButton in each `AttachmentCell`
    open var tintColor: UIColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    // MARK: - InputPlugin

    open func reloadData() {
        attachmentView.reloadData()
        delegate?.attachmentManager(self, didReloadTo: attachments)
        delegate?.attachmentManager(self, shouldBecomeVisible: !attachments.isEmpty || isPersistent)
    }

    /// Invalidates the `AttachmentManagers` session by removing all attachments
    open func invalidate() {
        attachments = []
    }

    /// Appends the object to the attachments
    ///
    /// - Parameter object: The object to append
    @discardableResult
    open func handleInput(of object: AnyObject) -> Bool {
        let attachment: Attachment
        if let image = object as? UIImage {
            attachment = .image(image)
        } else if let url = object as? URL {
            attachment = .url(url)
        } else if let data = object as? Data {
            attachment = .data(data)
        } else {
            return false
        }

        insertAttachment(attachment, at: attachments.count)
        return true
    }

    // MARK: - API [Public]

    /// Performs an animated insertion of an attachment at an index
    ///
    /// - Parameter index: The index to insert the attachment at
    open func insertAttachment(_ attachment: Attachment, at index: Int) {

        attachmentView.performBatchUpdates({
            self.attachments.insert(attachment, at: index)
            self.attachmentView.insertItems(at: [IndexPath(row: index, section: 0)])
        }, completion: { _ in
            self.attachmentView.reloadData()
            self.delegate?.attachmentManager(self, didInsert: attachment, at: index)
            self.delegate?.attachmentManager(self, shouldBecomeVisible: !self.attachments.isEmpty || self.isPersistent)
        })
    }

    /// Performs an animated removal of an attachment at an index
    ///
    /// - Parameter index: The index to remove the attachment at
    open func removeAttachment(at index: Int) {

        let attachment = attachments[index]
        attachmentView.performBatchUpdates({
            self.attachments.remove(at: index)
            self.attachmentView.deleteItems(at: [IndexPath(row: index, section: 0)])
        }, completion: { _ in
            self.attachmentView.reloadData()
            self.delegate?.attachmentManager(self, didRemove: attachment, at: index)
            self.delegate?.attachmentManager(self, shouldBecomeVisible: !self.attachments.isEmpty || self.isPersistent)
        })
    }

}

extension AttachmentManager: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - UICollectionViewDelegate

    public final func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == attachments.count {
            delegate?.attachmentManager(self, didSelectAddAttachmentAt: indexPath.row)
            delegate?.attachmentManager(self, shouldBecomeVisible: !attachments.isEmpty || isPersistent)
        }
    }

    // MARK: - UICollectionViewDataSource

    public final func numberOfItems(inSection section: Int) -> Int {
        return 1
    }

    public final func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count + (showAddAttachmentCell ? 1 : 0)
    }

    public final func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.row == attachments.count, showAddAttachmentCell {
            return createAttachmentCell(in: collectionView, at: indexPath)
        }

        let attachment = attachments[indexPath.row]

        if let cell = dataSource?.attachmentManager(self, cellFor: attachment, at: indexPath.row) {
            return cell
        } else {

            // Only images are supported by default
            switch attachment {
            case let .image(image):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageAttachmentCell.reuseIdentifier, for: indexPath) as? ImageAttachmentCell else {
                    fatalError()
                }
                cell.attachment = attachment
                cell.indexPath = indexPath
                cell.manager = self
                cell.imageView.image = image
                cell.imageView.tintColor = tintColor
                cell.deleteButton.backgroundColor = tintColor
                return cell
            default:
                return collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCell.reuseIdentifier, for: indexPath) as! AttachmentCell
            }

        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public final func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        var height = attachmentView.intrinsicContentHeight
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            height -= (layout.sectionInset.bottom + layout.sectionInset.top + collectionView.contentInset.top + collectionView.contentInset.bottom)
        }
        return CGSize(width: height, height: height)
    }

    open func createAttachmentCell(in collectionView: UICollectionView, at indexPath: IndexPath) -> AttachmentCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCell.reuseIdentifier, for: indexPath) as? AttachmentCell else {
            fatalError()
        }
        cell.deleteButton.isHidden = true
        // Draw a plus
        let frame = CGRect(origin: CGPoint(x: cell.bounds.origin.x,
                                           y: cell.bounds.origin.y),
                           size: CGSize(width: cell.bounds.width - cell.padding.left - cell.padding.right,
                                        height: cell.bounds.height - cell.padding.top - cell.padding.bottom))
        let strokeWidth: CGFloat = 3
        let length: CGFloat = frame.width / 2
        let vLayer = CAShapeLayer()
        vLayer.path = UIBezierPath(roundedRect: CGRect(x: frame.midX - (strokeWidth / 2),
                                                       y: frame.midY - (length / 2),
                                                       width: strokeWidth,
                                                       height: length), cornerRadius: 5).cgPath
        vLayer.fillColor = UIColor.lightGray.cgColor
        let hLayer = CAShapeLayer()
        hLayer.path = UIBezierPath(roundedRect: CGRect(x: frame.midX - (length / 2),
                                                       y: frame.midY - (strokeWidth / 2),
                                                       width: length,
                                                       height: strokeWidth), cornerRadius: 5).cgPath
        hLayer.fillColor = UIColor.lightGray.cgColor
        cell.containerView.layer.addSublayer(vLayer)
        cell.containerView.layer.addSublayer(hLayer)
        return cell
    }
}
