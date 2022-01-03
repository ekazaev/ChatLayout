//
// Created by Eugene Kazaev on 03/01/2022.
// Copyright (c) 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

final class ModelItem {
    weak var prev: ModelItem?
    var origin: CGPoint {
        guard let prev = prev else {
            return .zero
        }
        return CGPoint(x: 0, y: prev.origin.y + prev.size.height)
    }

    var frame: CGRect {
        return CGRect(origin: origin, size: size)
    }

    var size: CGSize

    init(prev: ModelItem? = nil, size: CGSize) {
        self.prev = prev
        self.size = size
    }
}