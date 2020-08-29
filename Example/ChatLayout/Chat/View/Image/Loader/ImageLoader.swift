//
// ChatLayout
// ImageLoader.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

public protocol ImageLoader {

    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)

}
