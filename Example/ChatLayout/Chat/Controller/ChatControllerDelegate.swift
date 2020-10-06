//
// ChatLayout
// ChatControllerDelegate.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

protocol ChatControllerDelegate: AnyObject {

    func update(with sections: [Section])

}
