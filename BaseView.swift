//
//  BaseView.swift
//  Pods
//
//  Created by JH on 2024/10/11.
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

open class BaseView: NSUIView {
    public var layoutMargins: NSUIEdgeInsets = .zero {
        didSet {
            guard layoutMargins != oldValue else { return }
            setupLayoutGuideConstraints()
        }
    }
    
    public let customLayoutMarginsGuide = NSLayoutGuide()
    
    private var topConstraint: NSLayoutConstraint?
    
    private var bottomConstraint: NSLayoutConstraint?
    
    private var leftConstraint: NSLayoutConstraint?
    
    private var rightConstraint: NSLayoutConstraint?
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func setupLayoutGuideConstraints() {
        topConstraint?.constant = layoutMargins.top
        bottomConstraint?.constant = -layoutMargins.bottom
        leftConstraint?.constant = layoutMargins.left
        rightConstraint?.constant = -layoutMargins.right
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
        self.topConstraint = topConstraint
        self.bottomConstraint = bottomConstraint
        self.leftConstraint = leftConstraint
        self.rightConstraint = rightConstraint
    }
}

#endif

#if canImport(UIKit)
import UIKit

public typealias BaseView = NSUIView
#endif


