//
// ChatLayout
// ImageMessageSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

enum ImageMessageSource: Hashable {

    case image(UIImage)

    case imageURL(URL)

}
