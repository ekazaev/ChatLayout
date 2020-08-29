//
// ChatLayout
// AutocompleteCompletion.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

public struct AutocompleteCompletion {

    // The String to insert/replace upon autocompletion
    public let text: String

    // The context of the completion that you may need later when completed
    public let context: [String: Any]?

    public init(text: String, context: [String: Any]? = nil) {
        self.text = text
        self.context = context
    }

    @available(*, deprecated, message: "`displayText` should no longer be used, use `context: [String: Any]` instead")
    public init(_ text: String, displayText: String) {
        self.text = text
        self.context = nil
    }
}
