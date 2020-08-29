//
// ChatLayout
// AttachmentManagerDataSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

/// AttachmentManagerDataSource is a protocol to passes data to the AttachmentManager
public protocol AttachmentManagerDataSource: AnyObject {

    /// The AttachmentCell for the attachment that is to be inserted into the AttachmentView
    ///
    /// - Parameters:
    ///   - manager: The AttachmentManager
    ///   - attachment: The object
    ///   - index: The index in the AttachmentView
    /// - Returns: An AttachmentCell
    func attachmentManager(_ manager: AttachmentManager, cellFor attachment: AttachmentManager.Attachment, at index: Int) -> AttachmentCell
}
