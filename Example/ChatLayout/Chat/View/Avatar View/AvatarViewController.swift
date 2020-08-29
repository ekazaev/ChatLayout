//
// ChatLayout
// AvatarViewController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

final class AvatarViewController {

    var image: UIImage? {
        guard bubble == .tailed else {
            return nil
        }
        switch user.id {
        case 0:
            return nil
        case 1:
            return UIImage(named: "Eugene")
        case 2:
            return UIImage(named: "Cathal")
        case 3:
            return UIImage(named: "Sasha")
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
