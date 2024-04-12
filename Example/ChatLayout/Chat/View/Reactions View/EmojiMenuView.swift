//
// ChatLayout
// EmojiMenuView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import RecyclerView
import UIKit

final class EmojiMenuView: UIView, CustomContextMenuAccessoryView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    private lazy var stackView = UIStackView(frame: bounds)
    private lazy var backgroundVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    @available(*, unavailable, message: "Use init(reuseIdentifier:) instead")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        addSubview(backgroundVisualEffectView)
        backgroundVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        backgroundVisualEffectView.layer.cornerRadius = 16
        backgroundVisualEffectView.layer.masksToBounds = true

        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            backgroundVisualEffectView.topAnchor.constraint(equalTo: topAnchor),
            backgroundVisualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundVisualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundVisualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),

            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])

        ["👍", "\u{2764}\u{fe0f}", "😂", "🔥", "🙏", "😢"].forEach { string in
            let label = UILabel()
            label.text = string
            label.font = .preferredFont(forTextStyle: .title1)
            label.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(label)
        }

        selectionFeedbackGenerator.prepare()

        layer.shadowRadius = 30
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .zero
    }

    func handleCustomContextMenuPointerSession(_ session: CustomContextMenuPointerSession) {
        guard bounds.contains(session.location(in: self)) else {
            stackView.arrangedSubviews.forEach { view in
                UIView.animate(withDuration: 0.25, animations: {
                    view.transform = .identity
                    view.layer.shadowOpacity = 0
                    view.layer.shadowRadius = 0
                })
            }
            return
        }
        switch session.state {
        case .began,
             .changed:
            stackView.arrangedSubviews.forEach { view in
                let touchPoint = session.location(in: stackView)
                let viewFrame = view.frameWithoutTransform.insetBy(dx: -8, dy: -16)
                if viewFrame.contains(touchPoint),
                   view.transform == .identity {
                    UIView.animate(withDuration: 0.25, animations: {
                        view.layer.shadowOpacity = 0.5
                        view.layer.shadowRadius = 20
                        view.transform = .identity.scaledBy(x: 1.6, y: 1.6).translatedBy(x: 0, y: -(view.bounds.height / 2 + 0))
                    })
                    selectionFeedbackGenerator.selectionChanged()
                }
                if !viewFrame.contains(touchPoint),
                   view.transform != .identity {
                    UIView.animate(withDuration: 0.25, animations: {
                        view.transform = .identity
                        view.layer.shadowOpacity = 0
                        view.layer.shadowRadius = 0
                    })
                }
            }
        case .ended:
            stackView.arrangedSubviews.forEach { view in
                UIView.animate(withDuration: 0.25, animations: {
                    view.transform = .identity
                    view.layer.shadowOpacity = 0
                    view.layer.shadowRadius = 0
                })
            }
            session.finalise()
        default:
            stackView.arrangedSubviews.forEach { view in
                UIView.animate(withDuration: 0.25, animations: {
                    view.transform = .identity
                    view.layer.shadowOpacity = 0
                    view.layer.shadowRadius = 0
                })
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundVisualEffectView.layer.cornerRadius = bounds.height / 2
    }
}

extension UIView {
    var frameWithoutTransform: CGRect {
        let center = center
        let size = bounds.size

        return CGRect(x: center.x - size.width / 2,
                      y: center.y - size.height / 2,
                      width: size.width,
                      height: size.height)
    }
}
