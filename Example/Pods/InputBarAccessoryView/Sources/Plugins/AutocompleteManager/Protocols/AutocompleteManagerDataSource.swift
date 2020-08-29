//
// ChatLayout
// AutocompleteManagerDataSource.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

/// AutocompleteManagerDataSource is a protocol that passes data to the AutocompleteManager
public protocol AutocompleteManagerDataSource: AnyObject {

    /// The autocomplete options for the registered prefix.
    ///
    /// - Parameters:
    ///   - manager: The AutocompleteManager
    ///   - prefix: The registered prefix
    /// - Returns: An array of `AutocompleteCompletion` options for the given prefix
    func autocompleteManager(_ manager: AutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion]

    /// The cell to populate the `AutocompleteTableView` with
    ///
    /// - Parameters:
    ///   - manager: The `AttachmentManager` that sources the UITableViewDataSource
    ///   - tableView: The `AttachmentManager`'s `AutocompleteTableView`
    ///   - indexPath: The `IndexPath` of the cell
    ///   - session: The current `Session` of the `AutocompleteManager`
    /// - Returns: A UITableViewCell to populate the `AutocompleteTableView`
    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell
}

public extension AutocompleteManagerDataSource {

    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: AutocompleteCell.reuseIdentifier, for: indexPath) as? AutocompleteCell else {
            fatalError("AutocompleteCell is not registered")
        }

        cell.textLabel?.attributedText = manager.attributedText(matching: session, fontSize: 13)
        cell.backgroundColor = .white
        cell.separatorLine.isHidden = tableView.numberOfRows(inSection: indexPath.section) - 1 == indexPath.row
        return cell

    }

}
