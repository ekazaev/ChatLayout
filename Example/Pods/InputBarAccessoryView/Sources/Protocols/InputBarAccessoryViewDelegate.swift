//
// ChatLayout
// InputBarAccessoryViewDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// InputBarAccessoryViewDelegate is a protocol that can recieve notifications from the InputBarAccessoryView
public protocol InputBarAccessoryViewDelegate: AnyObject {

    /// Called when the default send button has been selected
    ///
    /// - Parameters:
    ///   - inputBar: The InputBarAccessoryView
    ///   - text: The current text in the InputBarAccessoryView's InputTextView
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String)

    /// Called when the instrinsicContentSize of the InputBarAccessoryView has changed. Can be used for adjusting content insets
    /// on other views to make sure the InputBarAccessoryView does not cover up any other view
    ///
    /// - Parameters:
    ///   - inputBar: The InputBarAccessoryView
    ///   - size: The new instrinsicContentSize
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize)

    /// Called when the InputBarAccessoryView's InputTextView's text has changed. Useful for adding your own logic without the
    /// need of assigning a delegate or notification
    ///
    /// - Parameters:
    ///   - inputBar: The InputBarAccessoryView
    ///   - text: The current text in the InputBarAccessoryView's InputTextView
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String)

    /// Called when a swipe gesture was recognized on the InputBarAccessoryView's InputTextView
    ///
    /// - Parameters:
    ///   - inputBar: The InputBarAccessoryView
    ///   - gesture: The gesture that was recognized
    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer)
}

public extension InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {}

    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {}

    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {}

    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) {}
}
