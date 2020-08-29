//
// ChatLayout
// AttachmentManagerDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/// AttachmentManagerDelegate is a protocol that can recieve notifications from the AttachmentManager
public protocol AttachmentManagerDelegate: AnyObject {

    /// Can be used to determine if the AttachmentManager should be inserted into an InputStackView
    ///
    /// - Parameters:
    ///   - manager: The AttachmentManager
    ///   - shouldBecomeVisible: If the AttachmentManager should be presented or dismissed
    func attachmentManager(_ manager: AttachmentManager, shouldBecomeVisible: Bool)

    /// Notifys when an attachment has been inserted into the AttachmentManager
    ///
    /// - Parameters:
    ///   - manager: The AttachmentManager
    ///   - attachment: The attachment that was inserted
    ///   - index: The index of the attachment in the AttachmentManager's attachments array
    func attachmentManager(_ manager: AttachmentManager, didInsert attachment: AttachmentManager.Attachment, at index: Int)

    /// Notifys when an attachment has been removed from the AttachmentManager
    ///
    /// - Parameters:
    ///   - manager: The AttachmentManager
    ///   - attachment: The attachment that was removed
    ///   - index: The index of the attachment in the AttachmentManager's attachments array
    func attachmentManager(_ manager: AttachmentManager, didRemove attachment: AttachmentManager.Attachment, at index: Int)

    /// Notifys when the AttachmentManager was reloaded
    ///
    /// - Parameters:
    ///   - manager: The AttachmentManager
    ///   - attachments: The AttachmentManager's attachments array
    func attachmentManager(_ manager: AttachmentManager, didReloadTo attachments: [AttachmentManager.Attachment])

    /// Notifys when the AddAttachmentCell was selected
    ///
    /// - Parameters:
    ///   - manager: The AttachmentManager
    ///   - attachments: The index of the AddAttachmentCell
    func attachmentManager(_ manager: AttachmentManager, didSelectAddAttachmentAt index: Int)
}

public extension AttachmentManagerDelegate {

    func attachmentManager(_ manager: AttachmentManager, didInsert attachment: AttachmentManager.Attachment, at index: Int) {}

    func attachmentManager(_ manager: AttachmentManager, didRemove attachment: AttachmentManager.Attachment, at index: Int) {}

    func attachmentManager(_ manager: AttachmentManager, didReloadTo attachments: [AttachmentManager.Attachment]) {}

    func attachmentManager(_ manager: AttachmentManager, didSelectAddAttachmentAt index: Int) {}
}
