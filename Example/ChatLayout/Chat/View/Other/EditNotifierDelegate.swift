//
// ChatLayout
// EditNotifierDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

public enum ActionDuration {

    case notAnimated
    case animated(duration: TimeInterval)

}

public protocol EditNotifierDelegate: AnyObject {

    func setIsEditing(_ isEditing: Bool, duration: ActionDuration)

}

public extension EditNotifierDelegate {

    func setIsEditing(_ isEditing: Bool, duration: ActionDuration) {}

}
