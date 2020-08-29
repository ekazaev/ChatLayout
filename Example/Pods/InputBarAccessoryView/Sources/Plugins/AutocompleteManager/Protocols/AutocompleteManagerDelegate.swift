//
// ChatLayout
// AutocompleteManagerDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/// AutocompleteManagerDelegate is a protocol that more precisely define AutocompleteManager logic
public protocol AutocompleteManagerDelegate: AnyObject {

    /// Can be used to determine if the AutocompleteManager should be inserted into an InputStackView
    ///
    /// - Parameters:
    ///   - manager: The AutocompleteManager
    ///   - shouldBecomeVisible: If the AutocompleteManager should be presented or dismissed
    func autocompleteManager(_ manager: AutocompleteManager, shouldBecomeVisible: Bool)

    /// Determines if a prefix character should be registered to initialize the auto-complete selection table
    ///
    /// - Parameters:
    ///   - manager: The AutocompleteManager
    ///   - prefix: The prefix `Character` could be registered
    ///   - range: The `NSRange` of the prefix in the UITextView managed by the AutocompleteManager
    /// - Returns: If the prefix should be registered. Default is TRUE
    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool

    /// Determines if a prefix character should be unregistered to de-initialize the auto-complete selection table
    ///
    /// - Parameters:
    ///   - manager: The AutocompleteManager
    ///   - prefix: The prefix character could be unregistered
    ///   - range: The range of the prefix in the UITextView managed by the AutocompleteManager
    /// - Returns: If the prefix should be unregistered. Default is TRUE
    func autocompleteManager(_ manager: AutocompleteManager, shouldUnregister prefix: String) -> Bool

    /// Determines if a prefix character can should be autocompleted
    ///
    /// - Parameters:
    ///   - manager: The AutocompleteManager
    ///   - prefix: The prefix character that is currently registered
    ///   - text: The text to autocomplete with
    /// - Returns: If the prefix can be autocompleted. Default is TRUE
    func autocompleteManager(_ manager: AutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool
}

public extension AutocompleteManagerDelegate {

    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool {
        return true
    }

    func autocompleteManager(_ manager: AutocompleteManager, shouldUnregister prefix: String) -> Bool {
        return true
    }

    func autocompleteManager(_ manager: AutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool {
        return true
    }
}
