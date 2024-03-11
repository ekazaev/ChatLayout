//
// ChatLayout
// Section.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import DifferenceKit
import Foundation

struct Section: Hashable {
    var id: Int

    var title: String

    var cells: [Cell]
}

extension Section: DifferentiableSection {
    public var differenceIdentifier: Int {
        id
    }

    public func isContentEqual(to source: Section) -> Bool {
        id == source.id
    }

    public var elements: [Cell] {
        cells
    }

    public init<C: Swift.Collection>(source: Section, elements: C) where C.Element == Cell {
        self.init(id: source.id, title: source.title, cells: Array(elements))
    }
}
