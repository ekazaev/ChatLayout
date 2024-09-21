//
// ChatLayout
// ManualAnimator.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

// Read why this class is needed here:
// https://dasdom.dev/posts/scrolling-a-collection-view-with-custom-duration/
class ManualAnimator {
    enum AnimationCurve {
        case linear
        case parametric
        case easeInOut
        case easeIn
        case easeOut

        func modify(_ x: CGFloat) -> CGFloat {
            switch self {
            case .linear:
                x
            case .parametric:
                x.parametric
            case .easeInOut:
                x.quadraticEaseInOut
            case .easeIn:
                x.quadraticEaseIn
            case .easeOut:
                x.quadraticEaseOut
            }
        }
    }

    private var displayLink: CADisplayLink?
    private var start = Date()
    private var total = TimeInterval(0)
    private var closure: ((CGFloat) -> Void)?
    private var animationCurve: AnimationCurve = .linear

    func animate(duration: TimeInterval, curve: AnimationCurve = .linear, _ animations: @escaping (CGFloat) -> Void) {
        guard duration > 0 else {
            animations(1.0); return
        }
        reset()
        start = Date()
        closure = animations
        total = duration
        animationCurve = curve
        let d = CADisplayLink(target: self, selector: #selector(tick))
        d.add(to: .current, forMode: .common)
        displayLink = d
    }

    @objc
    private func tick() {
        let delta = Date().timeIntervalSince(start)
        var percentage = animationCurve.modify(CGFloat(delta) / CGFloat(total))
        if percentage < 0.0 {
            percentage = 0.0
        } else if percentage >= 1.0 {
            percentage = 1.0
            reset()
        }
        closure?(percentage)
    }

    private func reset() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

private extension CGFloat {
    var parametric: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        return (self * self) / (2.0 * ((self * self) - self) + 1.0)
    }

    var quadraticEaseInOut: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        if self < 0.5 {
            return 2 * self * self
        }
        return (-2 * self * self) + (4 * self) - 1
    }

    var quadraticEaseOut: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        return -self * (self - 2)
    }

    var quadraticEaseIn: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        return self * self
    }
}
