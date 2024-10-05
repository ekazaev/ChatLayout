//
// ChatLayout
// ItemKind.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
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

/// Type of the item supported by `CollectionViewChatLayout`
public enum ItemKind: CaseIterable, Hashable {
    /// Header item
    case header

    /// Cell item
    case cell

    /// Footer item
    case footer

    init(_ elementKind: String) {
        switch elementKind {
        case NSUICollectionView.elementKindSectionHeader:
            self = .header
        case NSUICollectionView.elementKindSectionFooter:
            self = .footer
        default:
            preconditionFailure("Unsupported supplementary view kind.")
        }
    }

    /// Returns: `true` if this `ItemKind` is equal to `ItemKind.header` or `ItemKind.footer`
    public var isSupplementaryItem: Bool {
        switch self {
        case .cell:
            false
        case .footer,
             .header:
            true
        }
    }

    var supplementaryElementStringType: String {
        switch self {
        case .cell:
            preconditionFailure("Cell type is not a supplementary view.")
        case .header:
            return NSUICollectionView.elementKindSectionHeader
        case .footer:
            return NSUICollectionView.elementKindSectionFooter
        }
    }
}
