//
// ChatLayout
// DateAccessoryView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation
import UIKit

final class DateAccessoryView: UIView {

    private var accessoryView = UILabel()

    private var controller: DateAccessoryController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func setup(with controller: DateAccessoryController) {
        self.controller = controller
        reloadData()
    }

    private func reloadData() {
        accessoryView.text = controller?.accessoryText
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        addSubview(accessoryView)
        accessoryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        accessoryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        accessoryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        accessoryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true

        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        accessoryView.font = UIFont.preferredFont(forTextStyle: .caption1)
        accessoryView.textColor = .gray
    }

}
