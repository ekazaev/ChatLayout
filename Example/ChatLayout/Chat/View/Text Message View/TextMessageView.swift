//
// ChatLayout
// TextMessageView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
import UIKit

final class TextMessageView: UIView, ContainerCollectionViewCellDelegate {
    private var viewPortWidth: CGFloat = 300

    private lazy var textView = MessageTextView()

    private var controller: TextMessageController?

    private var textViewWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func prepareForReuse() {
        textView.resignFirstResponder()
    }

    // Uncomment this method to test the performance without calculating text cell size using autolayout
    // For the better illustration set DefaultRandomDataProvider.enableRichContent/enableNewMessages
    // to false
//    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes? {
//        viewPortWidth = layoutAttributes.layoutFrame.width
//        guard let text = controller?.text as NSString? else {
//            return layoutAttributes
//        }
//        let maxWidth = viewPortWidth * Constants.maxWidth
//        var rect = text.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
//            options: [.usesLineFragmentOrigin, .usesFontLeading],
//            attributes: [NSAttributedString.Key.font: textView.font as Any], context: nil)
//        rect = rect.insetBy(dx: 0, dy: -8)
//        layoutAttributes.size = CGSize(width: layoutAttributes.layoutFrame.width, height: rect.height)
//        setupSize()
//        return layoutAttributes
//    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
    }

    func setup(with controller: TextMessageController) {
        self.controller = controller
        reloadData()
    }

    func reloadData() {
        guard let controller else {
            return
        }
        textView.text = controller.text
        UIView.performWithoutAnimation {
            if #available(iOS 13.0, *) {
                textView.textColor = controller.type.isIncoming ? UIColor.label : .systemBackground
                textView.linkTextAttributes = [.foregroundColor: controller.type.isIncoming ? UIColor.systemBlue : .systemGray6,
                                               .underlineStyle: 1]
            } else {
                let color = controller.type.isIncoming ? UIColor.black : .white
                textView.textColor = color
                textView.linkTextAttributes = [.foregroundColor: color,
                                               .underlineStyle: 1]
            }
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.spellCheckingType = .no
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = .all
        textView.font = .preferredFont(forTextStyle: .body)
        textView.scrollsToTop = false
        textView.bounces = false
        textView.bouncesZoom = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isExclusiveTouch = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
        textViewWidthConstraint = textView.widthAnchor.constraint(lessThanOrEqualToConstant: viewPortWidth)
        textViewWidthConstraint?.isActive = true

        let view = BezierView(frame: .init(origin: .zero, size: .init(width: 50, height: 50)))
        addSubview(view)
    }

    private func setupSize() {
        UIView.performWithoutAnimation {
            self.textViewWidthConstraint?.constant = viewPortWidth * Constants.maxWidth
            setNeedsLayout()
        }
    }
}

extension TextMessageView: AvatarViewDelegate {
    func avatarTapped() {
        if enableSelfSizingSupport {
            layoutMargins = layoutMargins == .zero ? UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0) : .zero
            setNeedsLayout()
            if let cell = superview(of: UICollectionViewCell.self) {
                cell.contentView.invalidateIntrinsicContentSize()
            }
        }
    }
}

/// UITextView with hacks to avoid selection
private final class MessageTextView: UITextView {
    override var isFocused: Bool {
        false
    }

    override var canBecomeFirstResponder: Bool {
        false
    }

    override var canBecomeFocused: Bool {
        false
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }
}

protocol PathPart {
    var initialPoint: CGPoint { get }
    func addToPath(_ path: UIBezierPath)
}

let curveSize: CGFloat = 16

struct FromMePathPart: PathPart {
    var frame: CGRect

    var initialPoint: CGPoint {
        CGPoint(x: frame.width, y: frame.height / 2)
    }

    func addToPath(_ path: UIBezierPath) {
        let fromPoint = CGPoint(x: frame.minX + curveSize, y: frame.center.y)
        path.addLine(to: fromPoint)
        let toPoint = CGPoint(x: frame.minX, y: frame.center.y + curveSize)
        path.addCurve(to: toPoint, controlPoint1: CGPoint(x: fromPoint.x - abs(fromPoint.x - toPoint.x) * 0.65, y: fromPoint.y), controlPoint2: CGPoint(x: toPoint.x, y: toPoint.y - abs(fromPoint.y - toPoint.y) * 0.65))
        path.addLine(to: CGPoint(x: frame.minX, y: frame.maxY))
    }
}


final class BezierView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        let path = UIBezierPath()
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        path.lineWidth = 20

        let part = FromMePathPart(frame: bounds)
        path.move(to: part.initialPoint)
        part.addToPath(path)

//        path.move(to: CGPoint(x: bounds.width, y: bounds.height / 2))
//        let fromPoint = CGPoint(x: bounds.width - 10, y: bounds.height / 2)
//        path.addLine(to: CGPoint(x: bounds.width - 10, y: bounds.height / 2))
//        let toPoint = CGPoint(x: bounds.width / 2, y: bounds.height - 10)
//        path.addCurve(to: toPoint, controlPoint1: CGPoint(x: fromPoint.x - abs(fromPoint.x - toPoint.x) * 0.65, y: fromPoint.y), controlPoint2: CGPoint(x: toPoint.x, y: toPoint.y - abs(fromPoint.y - toPoint.y) * 0.65))
//        path.addLine(to: CGPoint(x: bounds.width / 2, y: bounds.height))

        //adding calyer
        let cursorLayer = CAShapeLayer()
        cursorLayer.lineWidth = 4;
        cursorLayer.path = path.cgPath
        cursorLayer.strokeColor = UIColor.black.cgColor
        cursorLayer.fillColor = nil
        cursorLayer.lineCap = .round
        cursorLayer.lineJoin = .round

        self.layer.addSublayer(cursorLayer)
    }

}

extension CGRect {
    func rounded(_ rule: FloatingPointRoundingRule = .up) -> CGRect {
        CGRect(x: minX, y: minY, width: width.rounded(rule), height: height.rounded(rule))
    }

    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }

    /** the coordinates of this rectangles center */
    var center: CGPoint {
        get { CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }

    /** the x-coordinate of this rectangles center
     - note: Acts as a settable midX
     - returns: The x-coordinate of the center
      */
    var centerX: CGFloat {
        get { midX }
        set { origin.x = newValue - width * 0.5 }
    }

    /** the y-coordinate of this rectangles center
     - note: Acts as a settable midY
     - returns: The y-coordinate of the center
     */
    var centerY: CGFloat {
        get { midY }
        set { origin.y = newValue - height * 0.5 }
    }

    mutating func offsettingBy(dx: CGFloat, dy: CGFloat) {
        origin.x += dx
        origin.y += dy
    }
}
