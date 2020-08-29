//
// ChatLayout
// KeyboardNotification.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/// An object containing the key animation properties from NSNotification
public struct KeyboardNotification {

    // MARK: - Properties

    /// The event that triggered the transition
    public let event: KeyboardEvent

    /// The animation length the keyboards transition
    public let timeInterval: TimeInterval

    /// The animation properties of the keyboards transition
    public let animationOptions: UIView.AnimationOptions

    /// iPad supports split-screen apps, this indicates if the notification was for the current app
    public let isForCurrentApp: Bool

    /// The keyboards frame at the start of its transition
    public var startFrame: CGRect

    /// The keyboards frame at the beginning of its transition
    public var endFrame: CGRect

    /// Requires that the `NSNotification` is based on a `UIKeyboard...` event
    ///
    /// - Parameter notification: `KeyboardNotification`
    public init?(from notification: NSNotification) {
        guard notification.event != .unknown else { return nil }
        self.event = notification.event
        self.timeInterval = notification.timeInterval ?? 0.25
        self.animationOptions = notification.animationOptions
        self.isForCurrentApp = notification.isForCurrentApp ?? true
        self.startFrame = notification.startFrame ?? .zero
        self.endFrame = notification.endFrame ?? .zero
    }

}
