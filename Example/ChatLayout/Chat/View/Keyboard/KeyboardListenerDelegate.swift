//
// ChatLayout
// KeyboardListenerDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

protocol KeyboardListenerDelegate: AnyObject {

    func keyboardWillShow(info: KeyboardInfo)
    func keyboardDidShow(info: KeyboardInfo)
    func keyboardWillHide(info: KeyboardInfo)
    func keyboardDidHide(info: KeyboardInfo)
    func keyboardWillChangeFrame(info: KeyboardInfo)
    func keyboardDidChangeFrame(info: KeyboardInfo)

}

extension KeyboardListenerDelegate {

    func keyboardWillShow(info: KeyboardInfo) {}
    func keyboardDidShow(info: KeyboardInfo) {}
    func keyboardWillHide(info: KeyboardInfo) {}
    func keyboardDidHide(info: KeyboardInfo) {}
    func keyboardWillChangeFrame(info: KeyboardInfo) {}
    func keyboardDidChangeFrame(info: KeyboardInfo) {}

}
