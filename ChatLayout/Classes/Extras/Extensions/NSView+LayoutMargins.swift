//
//  BaseView.swift
//  Pods
//
//  Created by JH on 2024/10/11.
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSView {
    private static var layoutMarginsKey = malloc(1)!

    public var layoutMargins: NSUIEdgeInsets {
        set {
            objc_setAssociatedObject(self, Self.layoutMarginsKey, NSValue(edgeInsets: newValue), .OBJC_ASSOCIATION_COPY_NONATOMIC)
            setupLayoutGuideConstraints()
        }
        get {
            if let layoutMargins = objc_getAssociatedObject(self, Self.layoutMarginsKey) as? NSValue {
                return layoutMargins.edgeInsetsValue
            } else {
                return .zero
            }
        }
    }

    private static var customLayoutMarginsGuideKey = malloc(1)!

    public var customLayoutMarginsGuide: NSLayoutGuide {
        if let layoutGuide = objc_getAssociatedObject(self, Self.customLayoutMarginsGuideKey) as? NSLayoutGuide {
            return layoutGuide
        } else {
            let layoutGuide = NSLayoutGuide()
            objc_setAssociatedObject(self, Self.customLayoutMarginsGuideKey, layoutGuide, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            defer {
                commonInit()
            }
            return layoutGuide
        }
    }

    private class LayoutConstraints: NSObject {
        var topConstraint: NSLayoutConstraint?

        var bottomConstraint: NSLayoutConstraint?

        var leftConstraint: NSLayoutConstraint?

        var rightConstraint: NSLayoutConstraint?
    }

    private static var layoutConstraintsKey = malloc(1)!

    private var layoutConstraints: LayoutConstraints {
        if let layoutGuide = objc_getAssociatedObject(self, Self.layoutConstraintsKey) as? LayoutConstraints {
            return layoutGuide
        } else {
            let layoutGuide = LayoutConstraints()
            objc_setAssociatedObject(self, Self.layoutConstraintsKey, layoutGuide, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return layoutGuide
        }
    }

    private func setupLayoutGuideConstraints() {
        layoutConstraints.topConstraint?.constant = layoutMargins.top
        layoutConstraints.bottomConstraint?.constant = -layoutMargins.bottom
        layoutConstraints.leftConstraint?.constant = layoutMargins.left
        layoutConstraints.rightConstraint?.constant = -layoutMargins.right
    }

    private func commonInit() {
        addLayoutGuide(customLayoutMarginsGuide)
        let topConstraint = customLayoutMarginsGuide.topAnchor.constraint(equalTo: topAnchor)
        let bottomConstraint = customLayoutMarginsGuide.bottomAnchor.constraint(equalTo: bottomAnchor)
        let leftConstraint = customLayoutMarginsGuide.leftAnchor.constraint(equalTo: leftAnchor)
        let rightConstraint = customLayoutMarginsGuide.rightAnchor.constraint(equalTo: rightAnchor)
        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leftConstraint,
            rightConstraint,
        ])
        layoutConstraints.topConstraint = topConstraint
        layoutConstraints.bottomConstraint = bottomConstraint
        layoutConstraints.leftConstraint = leftConstraint
        layoutConstraints.rightConstraint = rightConstraint
    }
}

#endif
