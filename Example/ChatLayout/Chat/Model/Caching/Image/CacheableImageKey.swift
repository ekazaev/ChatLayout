//
// ChatLayout
// CacheableImageKey.swift
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

public struct CacheableImageKey: Hashable, PersistentlyCacheable {
    public let url: URL

    var persistentIdentifier: String {
        url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? url.absoluteString
    }
}
