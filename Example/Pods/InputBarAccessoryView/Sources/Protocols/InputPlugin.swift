//
// ChatLayout
// InputPlugin.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/// `InputPlugin` is a protocol that makes integrating plugins to the `InputBarAccessoryView` easy.
public protocol InputPlugin: AnyObject {

    /// Should reload the state if the `InputPlugin`
    func reloadData()

    /// Should remove any content that the `InputPlugin` is managing
    func invalidate()

    /// Should handle the input of data types that an `InputPlugin` manages
    ///
    /// - Parameter object: The object to input
    func handleInput(of object: AnyObject) -> Bool
}
