//
// ChatLayout
// ItemKind.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

/// Type of the item supported by `ChatLayout`
public enum ItemKind: CaseIterable, Hashable {

    /// Header item
    case header

    /// Cell item
    case cell

    /// Footer item
    case footer

    init(_ elementKind: String) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            self = .header
        case UICollectionView.elementKindSectionFooter:
            self = .footer
        default:
            fatalError("Unsupported supplementary view kind")
        }
    }

    var supplementaryElementStringType: String {
        switch self {
        case .cell:
            fatalError("Cell type is not a supplementary view")
        case .header:
            return UICollectionView.elementKindSectionHeader
        case .footer:
            return UICollectionView.elementKindSectionFooter
        }
    }

}
