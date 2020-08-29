//
// ChatLayout
// InputBarViewController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/// An simple `UIViewController` subclass that is ready to work
/// with an `inputAccessoryView`
open class InputBarViewController: UIViewController, InputBarAccessoryViewDelegate {

    /// A powerful InputAccessoryView ideal for messaging applications
    public let inputBar = InputBarAccessoryView()

    /// A boolean value that when changed will update the `inputAccessoryView`
    /// of the `InputBarViewController`. When set to `TRUE`, the
    /// `inputAccessoryView` is set to `nil` and the `inputBar` slides off
    /// the screen.
    ///
    /// The default value is FALSE
    open var isInputBarHidden: Bool = false {
        didSet {
            isInputBarHiddenDidChange()
        }
    }

    open override var inputAccessoryView: UIView? {
        return isInputBarHidden ? nil : inputBar
    }

    open override var canBecomeFirstResponder: Bool {
        return !isInputBarHidden
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        inputBar.delegate = self
    }

    /// Invoked when `isInputBarHidden` changes to become or
    /// resign first responder
    open func isInputBarHiddenDidChange() {
        if isInputBarHidden, isFirstResponder {
            resignFirstResponder()
        } else if !isFirstResponder {
            becomeFirstResponder()
        }
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        inputBar.inputTextView.resignFirstResponder()
        return super.resignFirstResponder()
    }

    // MARK: - InputBarAccessoryViewDelegate

    open func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {}

    open func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {}

    open func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {}

    open func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) {}
}
