//
// ChatLayout
// ImageLoader.swift
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

public protocol ImageLoader {
    func loadImage(from url: URL, completion: @escaping (Result<NSUIImage, Error>) -> Void)
}
