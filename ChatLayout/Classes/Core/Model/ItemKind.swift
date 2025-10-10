//
// ChatLayout
// ItemKind.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2025.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

/// Type of the item supported by `CollectionViewChatLayout`
public enum ItemKind: CaseIterable, Hashable, Sendable {
    /// Header item
    @available(*, deprecated, message: "Support for supplementary views is deprecated and will be discontinued in future versions.")
    case header

    /// Cell item
    case cell

    /// Footer item
    @available(*, deprecated, message: "Support for supplementary views is deprecated and will be discontinued in future versions.")
    case footer

    @available(*, deprecated, message: "Support for supplementary views is deprecated and will be discontinued in future versions.")
    init(_ elementKind: String) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            self = .header
        case UICollectionView.elementKindSectionFooter:
            self = .footer
        default:
            preconditionFailure("Unsupported supplementary view kind: \(elementKind).")
        }
    }

    /// Returns: `true` if this `ItemKind` is equal to `ItemKind.header` or `ItemKind.footer`
    @available(*, deprecated, message: "Support for supplementary views is deprecated and will be discontinued in future versions.")
    public var isSupplementaryItem: Bool {
        switch self {
        case .cell:
            false
        case .footer,
             .header:
            true
        }
    }

    @MainActor
    @available(*, deprecated, message: "Support for supplementary views is deprecated and will be discontinued in future versions.")
    var supplementaryElementStringType: String {
        switch self {
        case .cell:
            preconditionFailure("Cell type is not a supplementary view.")
        case .header:
            UICollectionView.elementKindSectionHeader
        case .footer:
            UICollectionView.elementKindSectionFooter
        }
    }

    /// A collection of all values of this type.
    public static var allCases: [ItemKind] { [.header, .cell, .footer] }
}
