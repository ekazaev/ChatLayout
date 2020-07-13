//
// ChatLayout
// ChatLayoutDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// `ChatLayout` delegate
public protocol ChatLayoutDelegate: AnyObject {

    /// `ChatLayout` will call this method to ask if it should present the header in the current layout.
    /// - Parameter sectionIndex: Index of the section.
    func shouldPresentHeader(at sectionIndex: Int) -> Bool

    /// `ChatLayout` will call this method to ask if it should present the footer in the current layout.
    /// - Parameter sectionIndex: Index of the section.
    func shouldPresentFooter(at sectionIndex: Int) -> Bool

    /// `ChatLayout` will call this method to ask what type of alignment the item should have.
    /// - Parameters:
    ///   - kind: Type of element represented by `ItemKind`.
    ///   - indexPath: Index path of the item.
    func alignmentForItem(of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment

    /// `ChatLayout` will call this method to ask what size the item should have.
    /// - Parameters:
    ///   - kind: Type of element represented by `ItemKind`.
    ///   - indexPath: Index path of the item.
    func sizeForItem(of kind: ItemKind, at indexPath: IndexPath) -> ItemSize

}

/// Default extension.
public extension ChatLayoutDelegate {

    func shouldPresentHeader(at sectionIndex: Int) -> Bool {
        return false
    }

    func shouldPresentFooter(at sectionIndex: Int) -> Bool {
        return false
    }

    func sizeForItem(of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
        return .auto
    }

    func alignmentForItem(of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment {
        return .full
    }

}
