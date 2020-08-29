//
// ChatLayout
// CacheableImageKey.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

public struct CacheableImageKey: Hashable, PersistentlyCacheable {

    public let url: URL

    var persistentIdentifier: String {
        return (url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? url.absoluteString)
    }

}
