//
// ChatLayout
// ChatItemPinningType.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

/// Represents pinning behavour of the element.
public enum ChatItemPinningType: Hashable, Sendable {
    /// Represents top edge of the visible area.
    case top

    /// Represents bottom edge of the visible area.
    case bottom
}
