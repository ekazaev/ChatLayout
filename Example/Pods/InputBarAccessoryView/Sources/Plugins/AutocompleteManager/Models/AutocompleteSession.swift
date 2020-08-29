//
// ChatLayout
// AutocompleteSession.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

/// A class containing data on the `AutocompleteManager`'s session
public class AutocompleteSession {

    public let prefix: String
    public let range: NSRange
    public var filter: String
    public var completion: AutocompleteCompletion?
    internal var spaceCounter: Int = 0

    public init?(prefix: String?, range: NSRange?, filter: String?) {
        guard let pfx = prefix, let rng = range, let flt = filter else { return nil }
        self.prefix = pfx
        self.range = rng
        self.filter = flt
    }
}

extension AutocompleteSession: Equatable {

    public static func == (lhs: AutocompleteSession, rhs: AutocompleteSession) -> Bool {
        return lhs.prefix == rhs.prefix && lhs.range == rhs.range
    }
}
