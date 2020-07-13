//
// ChatLayout
// ItemSize.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// Represents desired item size.
public enum ItemSize {

    /// Item size should be fully calculated by the `ChatLayout`. Initial estimated size will be taken from `ChatLayoutSettings`.
    case auto

    /// Item size should be fully calculated by the `ChatLayout`. Initial estimated size should be taken from the value provided.
    case estimated(CGSize)

    /// Item size should be exactly equal to the value provided.
    case exact(CGSize)

}
