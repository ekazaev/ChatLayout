//
// ChatLayout
// KeyboardListener.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

final class KeyboardListener {

    static let shared = KeyboardListener()

    private(set) var isKeyboardVisible: Bool = false

    private(set) var keyboardRect: CGRect?

    private var delegates = NSHashTable<AnyObject>.weakObjects()

    func add(delegate: KeyboardListenerDelegate) {
        delegates.add(delegate)
    }

    private init() {
        subscribeToKeyboardNotifications()
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = KeyboardInfo(notification) else {
            return
        }

        keyboardRect = info.frameEnd
        isKeyboardVisible = true
        delegates.allObjects.compactMap { $0 as? KeyboardListenerDelegate }.forEach {
            $0.keyboardWillShow(info: info)
        }
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let info = KeyboardInfo(notification) else {
            return
        }
        keyboardRect = info.frameEnd
        delegates.allObjects.compactMap { $0 as? KeyboardListenerDelegate }.forEach {
            $0.keyboardWillChangeFrame(info: info)
        }
    }

    @objc private func keyboardDidChangeFrame(_ notification: Notification) {
        guard let info = KeyboardInfo(notification) else {
            return
        }
        keyboardRect = info.frameEnd
        delegates.allObjects.compactMap { $0 as? KeyboardListenerDelegate }.forEach {
            $0.keyboardDidChangeFrame(info: info)
        }
    }

    @objc private func keyboardDidShow(_ notification: Notification) {
        guard let info = KeyboardInfo(notification) else {
            return
        }
        keyboardRect = info.frameEnd
        delegates.allObjects.compactMap { $0 as? KeyboardListenerDelegate }.forEach {
            $0.keyboardDidShow(info: info)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let info = KeyboardInfo(notification) else {
            return
        }
        keyboardRect = info.frameEnd
        delegates.allObjects.compactMap { $0 as? KeyboardListenerDelegate }.forEach {
            $0.keyboardWillHide(info: info)
        }
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        guard let info = KeyboardInfo(notification) else {
            return
        }
        keyboardRect = info.frameEnd
        isKeyboardVisible = false
        delegates.allObjects.compactMap { $0 as? KeyboardListenerDelegate }.forEach {
            $0.keyboardDidHide(info: info)
        }
    }

    private func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow(_:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide(_:)),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidChangeFrame(_:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
    }

}
