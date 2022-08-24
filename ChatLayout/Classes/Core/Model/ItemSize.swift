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
public enum ItemSize {

    /// Item size should be fully calculated by the `CollectionViewChatLayout`. Initial estimated size will be taken from `ChatLayoutSettings`.
    case auto

    /// Item size should be fully calculated by the `CollectionViewChatLayout`. Initial estimated size should be taken from the value provided.
    case estimated(CGSize)

    /// Item size should be exactly equal to the value provided.
    case exact(CGSize)

}
