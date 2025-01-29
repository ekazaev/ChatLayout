//
// ChatLayout
// AvatarViewController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

final class AvatarViewController {
    var image: NSUIImage? {
        guard bubble == .tailed else {
            return nil
        }
        switch user.id {
        case 0:
            return nil
        case 1:
            return NSUIImage(named: "Eugene")
        case 2:
            return NSUIImage(named: "Cathal")
        case 3:
            return NSUIImage(named: "Sasha")
        default:
            fatalError("Support for the user id \(user.id) is not implemented.")
        }
    }

    private let user: User

    private let bubble: Cell.BubbleType

    weak var view: AvatarView? {
        didSet {
            view?.reloadData()
        }
    }

    init(user: User, bubble: Cell.BubbleType) {
        self.user = user
        self.bubble = bubble
    }
}
