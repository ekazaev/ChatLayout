//
// ChatLayout
// ImageMessageSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

enum ImageMessageSource: Hashable {
    case image(UIImage)
    case imageURL(URL)
}
