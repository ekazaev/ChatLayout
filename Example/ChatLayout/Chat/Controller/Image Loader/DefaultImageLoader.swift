//
// ChatLayout
// DefaultImageLoader.swift
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

public struct DefaultImageLoader: ImageLoader {
    public enum ImageError: Error {
        case corruptedData
    }

    public init() {}

    public func loadImage(from url: URL) async throws -> UIImage {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
        let (imageData, _) = try await URLSession.shared.data(for: request)
        return try await Task.detached(priority: .utility) {
            guard let image = UIImage(data: imageData) else {
                throw ImageError.corruptedData
            }
            return image
        }.value
    }
}
