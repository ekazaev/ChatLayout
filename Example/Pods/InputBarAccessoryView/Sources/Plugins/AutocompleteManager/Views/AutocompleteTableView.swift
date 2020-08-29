//
// ChatLayout
// AutocompleteTableView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

open class AutocompleteTableView: UITableView {

    /// The max visible rows visible in the autocomplete table before the user has to scroll throught them
    open var maxVisibleRows = 3 { didSet { invalidateIntrinsicContentSize() } }

    open override var intrinsicContentSize: CGSize {

        let rows = numberOfRows(inSection: 0) < maxVisibleRows ? numberOfRows(inSection: 0) : maxVisibleRows
        return CGSize(width: super.intrinsicContentSize.width, height: CGFloat(rows) * rowHeight)
    }

}
