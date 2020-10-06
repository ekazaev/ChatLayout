//
// ChatLayout
// CGSize+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

extension CGSize {

    func equalRounded(to size: CGSize) -> Bool {
        return abs(size.width - size.width) <= 1 &&
            abs(size.height - size.height) <= 1
    }

}
