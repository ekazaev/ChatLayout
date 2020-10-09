//
// ChatLayout
// KeyboardInfo.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct KeyboardInfo: Equatable {

    let animationDuration: Double

    let animationCurve: UIView.AnimationCurve

    let frameBegin: CGRect

    let frameEnd: CGRect

    let isLocal: Bool

    init?(_ notification: Notification) {
        guard let userInfo: NSDictionary = notification.userInfo as NSDictionary?,
            let keyboardAnimationCurve = (userInfo.object(forKey: UIResponder.keyboardAnimationCurveUserInfoKey) as? NSValue) as? Int,
            let keyboardAnimationDuration = (userInfo.object(forKey: UIResponder.keyboardAnimationDurationUserInfoKey) as? NSValue) as? Double,
            let keyboardIsLocal = (userInfo.object(forKey: UIResponder.keyboardIsLocalUserInfoKey) as? NSValue) as? Bool,
            let keyboardFrameBegin = (userInfo.object(forKey: UIResponder.keyboardFrameBeginUserInfoKey) as? NSValue)?.cgRectValue,
            let keyboardFrameEnd = (userInfo.object(forKey: UIResponder.keyboardFrameEndUserInfoKey) as? NSValue)?.cgRectValue else {
            return nil
        }

        self.animationDuration = keyboardAnimationDuration
        var animationCurve = UIView.AnimationCurve.easeInOut
        NSNumber(value: keyboardAnimationCurve).getValue(&animationCurve)
        self.animationCurve = animationCurve
        self.isLocal = keyboardIsLocal
        self.frameBegin = keyboardFrameBegin
        self.frameEnd = keyboardFrameEnd
    }

}
