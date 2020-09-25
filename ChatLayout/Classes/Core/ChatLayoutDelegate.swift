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
    /// - Parameters:
    ///   - chatLayout: ChatLayout reference.
    ///   - sectionIndex: Index of the section.
    /// - Returns: `Bool`.
    func shouldPresentHeader(_ chatLayout: ChatLayout, at sectionIndex: Int) -> Bool

    /// `ChatLayout` will call this method to ask if it should present the footer in the current layout.
    /// - Parameters:
    ///   - chatLayout: ChatLayout reference.
    ///   - sectionIndex: Index of the section.
    /// - Returns: `Bool`.
    func shouldPresentFooter(_ chatLayout: ChatLayout, at sectionIndex: Int) -> Bool

    /// `ChatLayout` will call this method to ask what size the item should have.
    /// - Parameters:
    ///   - chatLayout: ChatLayout reference.
    ///   - kind: Type of element represented by `ItemKind`.
    ///   - indexPath: Index path of the item.
    /// - Returns: `ItemSize`.
    func sizeForItem(_ chatLayout: ChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ItemSize

    /// `ChatLayout` will call this method to ask what type of alignment the item should have.
    /// - Parameters:
    ///   - chatLayout: ChatLayout reference.
    ///   - kind: Type of element represented by `ItemKind`.
    ///   - indexPath: Index path of the item.
    /// - Returns: `ChatItemAlignment`.
    func alignmentForItem(_ chatLayout: ChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment

}

/// Default extension.
public extension ChatLayoutDelegate {

    /// Default implementation returns: `false`.
    func shouldPresentHeader(_ chatLayout: ChatLayout, at sectionIndex: Int) -> Bool {
        return false
    }

    /// Default implementation returns: `false`.
    func shouldPresentFooter(_ chatLayout: ChatLayout, at sectionIndex: Int) -> Bool {
        return false
    }

    /// Default implementation returns: `ItemSize.auto`.
    func sizeForItem(_ chatLayout: ChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
        return .auto
    }

    /// Default implementation returns: `ChatItemAlignment.full`.
    func alignmentForItem(_ chatLayout: ChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment {
        return .full
    }

}
