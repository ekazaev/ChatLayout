//
// ChatLayout
// InputBarSendButton.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

open class InputBarSendButton: InputBarButtonItem {

    /// A flag indicating the animation state of the `InputBarSendButton`
    open private(set) var isAnimating: Bool = false

    /// Accessor to modify the color of the activity view
    open var activityViewColor: UIColor! {
        get {
            return activityView.color
        }
        set {
            activityView.color = newValue
        }
    }

    private let activityView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSendButton()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSendButton()
    }

    private func setupSendButton() {
        addSubview(activityView)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        activityView.frame = bounds
    }

    /// Starts the animation of the activity view, hiding other elements
    open func startAnimating() {
        guard !isAnimating else { return }
        defer { isAnimating = true }
        activityView.startAnimating()
        activityView.isHidden = false
        // Setting isHidden doesn't hide the elements
        titleLabel?.alpha = 0
        imageView?.layer.transform = CATransform3DMakeScale(0.0, 0.0, 0.0)
    }

    /// Stops the animation of the activity view, shows other elements
    open func stopAnimating() {
        guard isAnimating else { return }
        defer { isAnimating = false }
        activityView.stopAnimating()
        activityView.isHidden = true
        titleLabel?.alpha = 1
        imageView?.layer.transform = CATransform3DIdentity
    }

}
