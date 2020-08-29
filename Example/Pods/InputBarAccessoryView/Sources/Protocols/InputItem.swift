//
// ChatLayout
// InputItem.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/// InputItem is a protocol that links elements to the InputBarAccessoryView to make them reactive
public protocol InputItem: AnyObject {

    /// A weak reference to the InputBarAccessoryView. Set when inserted into an InputStackView
    var inputBarAccessoryView: InputBarAccessoryView? { get set }

    /// A reference to the InputStackView that the InputItem is contained in. Set when inserted into an InputStackView
    var parentStackViewPosition: InputStackView.Position? { get set }

    /// A hook that is called when the InputTextView's text is changed
    func textViewDidChangeAction(with textView: InputTextView)

    /// A hook that is called when the InputBarAccessoryView's InputTextView receieves a swipe gesture
    func keyboardSwipeGestureAction(with gesture: UISwipeGestureRecognizer)

    /// A hook that is called when the InputTextView is resigned as the first responder
    func keyboardEditingEndsAction()

    /// A hook that is called when the InputTextView is made the first responder
    func keyboardEditingBeginsAction()
}
