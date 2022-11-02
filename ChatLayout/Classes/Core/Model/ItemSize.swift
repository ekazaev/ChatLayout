//
// ChatLayout
// ItemSize.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// Represents desired item size.
public enum ItemSize: Hashable {

    /// Item size should be fully calculated by the `CollectionViewChatLayout`. Initial estimated size will be taken from `ChatLayoutSettings`.
    case auto

    /// Item size should be fully calculated by the `CollectionViewChatLayout`. Initial estimated size should be taken from the value provided.
    case estimated(CGSize)

    /// Item size should be exactly equal to the value provided.
    case exact(CGSize)

    /// Represents current item size case type.
    public enum CaseType: Hashable, CaseIterable {
        /// Represents `ItemSize.auto`
        case auto
        /// Represents `ItemSize.estimated`
        case estimated
        /// Represents `ItemSize.exact`
        case exact
    }

    /// Returns current item size case type.
    public var caseType: CaseType {
        switch self {
        case .auto:
            return .auto
        case .estimated:
            return .estimated
        case .exact:
            return .exact
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(caseType)
        switch self {
        case .auto:
            break
        case let .estimated(size):
            hasher.combine(size.width)
            hasher.combine(size.height)
        case let .exact(size):
            hasher.combine(size.width)
            hasher.combine(size.height)
        }
    }

}
