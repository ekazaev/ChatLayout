//
// ChatLayout
// ImageLoader.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

public protocol ImageLoader: Sendable {
    func loadImage(from url: URL) async throws -> UIImage
}
