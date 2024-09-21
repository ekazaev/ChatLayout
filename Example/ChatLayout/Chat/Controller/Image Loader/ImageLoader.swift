//
// ChatLayout
// ImageLoader.swift
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

public protocol ImageLoader {
    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)
}
