#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSView {
    public enum ContentMode: Int, @unchecked Sendable {
        case scaleToFill = 0

        case scaleAspectFit = 1 // contents scaled to fit with fixed aspect. remainder is transparent

        case scaleAspectFill = 2 // contents scaled to fill with fixed aspect. some portion of content may be clipped.

        case redraw = 3 // redraw on bounds change (calls -setNeedsDisplay)

        case center = 4 // contents remain same size. positioned adjusted.

        case top = 5

        case bottom = 6

        case left = 7

        case right = 8

        case topLeft = 9

        case topRight = 10

        case bottomLeft = 11

        case bottomRight = 12
    }

    var contentMode: ContentMode {
        set {
            setWantsLayer()
            var contentGravity: CALayerContentsGravity = .resize
            switch newValue {
            case .scaleAspectFit:
                contentGravity = .resizeAspect
            case .scaleAspectFill:
                contentGravity = .resizeAspectFill
            case .redraw:
                layer?.needsDisplayOnBoundsChange = true
                return
            case .center:
                contentGravity = .center
            case .top:
                contentGravity = .top
            case .bottom:
                contentGravity = .bottom
            case .left:
                contentGravity = .left
            case .right:
                contentGravity = .right
            case .topLeft:
                contentGravity = .topLeft
            case .topRight:
                contentGravity = .topRight
            case .bottomLeft:
                contentGravity = .bottomLeft
            case .bottomRight:
                contentGravity = .bottomRight
            default:
                break
            }
            layer?.contentsGravity = contentGravity
        }
        get {
            setWantsLayer()
            if layer?.needsDisplayOnBoundsChange == true {
                return .redraw
            } else {
                if let contentGravity = layer?.contentsGravity, let contentMode = Self.contentModeForContentGravity[contentGravity] {
                    return contentMode
                } else {
                    return .scaleToFill
                }
            }
        }
    }

    static let contentModeForContentGravity: [CALayerContentsGravity: ContentMode] = [
        .center: .center,
        .top: .top,
        .bottom: .bottom,
        .left: .left,
        .right: .right,
        .topLeft: .topLeft,
        .topRight: .topRight,
        .bottomLeft: .bottomLeft,
        .bottomRight: .bottomRight,
        .resize: .scaleToFill,
        .resizeAspect: .scaleAspectFit,
        .resizeAspectFill: .scaleAspectFill,
    ]

    static func animate(withDuration duration: TimeInterval, animations: () -> Void, completion: ((Bool) -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = true
            context.duration = duration
            animations()
            context.completionHandler = {
                completion?(true)
            }
        }
    }

    static func performWithoutAnimation(_ block: () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            let allowsImplicitAnimation = context.allowsImplicitAnimation
            context.allowsImplicitAnimation = false
            block()
            context.allowsImplicitAnimation = allowsImplicitAnimation
        }
    }

    func layoutIfNeeded() {
        layoutSubtreeIfNeeded()
    }

    func setNeedsLayout() {
        needsLayout = true
    }

    func setNeedsDisplay() {
        needsDisplay = true
    }

    func setNeedsUpdateConstraints() {
        needsUpdateConstraints = true
    }

    var alpha: CGFloat {
        set {
            alphaValue = newValue
        }
        get {
            alphaValue
        }
    }

    func setWantsLayer() {
        wantsLayer = true
    }

    var transform: CGAffineTransform {
        set {
            setWantsLayer()
            layer?.setAffineTransform(newValue)
        }
        get {
            setWantsLayer()
            return layer?.affineTransform() ?? .identity
        }
    }

    var backgroundColor: NSColor? {
        set {
            setWantsLayer()
            layer?.backgroundColor = newValue?.cgColor
        }
        get {
            setWantsLayer()
            return layer?.backgroundColor.flatMap { NSColor(cgColor: $0) }
        }
    }
}

extension NSEdgeInsets {
    static func + (lhs: Self, rhs: Self) -> Self {
        return .init(top: lhs.top + rhs.top, left: lhs.left + rhs.left, bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
    }
}

extension NSCollectionView {
    func dequeueReusableSupplementaryView(
        ofKind elementKind: String,
        withReuseIdentifier identifier: String,
        for indexPath: IndexPath
    ) -> NSUICollectionReusableView {
        makeSupplementaryView(ofKind: elementKind, withIdentifier: .init(identifier), for: indexPath)
    }

    func dequeueReusableCell(withReuseIdentifier reuseIdentifier: String, for indexPath: IndexPath) -> NSUICollectionViewCell {
        makeItem(withIdentifier: .init(reuseIdentifier), for: indexPath)
    }

    func register(_ itemClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        register(itemClass, forItemWithIdentifier: .init(identifier))
    }

    func register(_ viewClass: AnyClass?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        register(viewClass, forSupplementaryViewOfKind: kind, withIdentifier: .init(identifier))
    }

    func deleteItems(at indexPaths: [IndexPath]) {
        let indexSets = Set(indexPaths)
        deleteItems(at: indexSets)
    }

    func insertItems(at indexPaths: [IndexPath]) {
        let indexSets = Set(indexPaths)
        insertItems(at: indexSets)
    }

    func reloadItems(at indexPaths: [IndexPath]) {
        let indexSets = Set(indexPaths)
        reloadItems(at: indexSets)
    }

    func performBatchUpdates(_ updates: () -> Void, completion: ((Bool) -> Void)? = nil) {
        animator().performBatchUpdates(updates, completionHandler: completion)
    }
}

extension NSViewController {
    var presentedViewController: NSViewController? {
        presentedViewControllers?.first
    }
}

extension NSImageView {
    var tintColor: NSColor? {
        set {
            contentTintColor = newValue
        }
        get {
            contentTintColor
        }
    }
}

extension NSImage {
    convenience init?(systemName: String) {
        self.init(systemSymbolName: systemName, accessibilityDescription: nil)
    }
}

extension NSCollectionViewLayoutAttributes {
    var transform: CGAffineTransform {
        set {
            setValue(NSValue(caTransform3D: CATransform3DMakeAffineTransform(newValue)), forKeyPath: #function)
        }
        get {
            (value(forKeyPath: #function) as? NSValue).map { CATransform3DGetAffineTransform($0.caTransform3DValue) } ?? .identity
        }
    }

    var bounds: CGRect {
        set {
            setValue(NSValue(rect: newValue), forKeyPath: #function)
        }
        get {
            (value(forKeyPath: #function) as? NSValue).map(\.rectValue) ?? .zero
        }
    }

    var center: CGPoint {
        set {
            setValue(NSValue(point: newValue), forKeyPath: #function)
        }
        get {
            (value(forKeyPath: #function) as? NSValue).map(\.pointValue) ?? .zero
        }
    }
}

extension NSEdgeInsets {
    static let zero = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}

extension NSProgressIndicator {
    func startAnimating() {
        startAnimation(nil)
    }

    func stopAnimating() {
        stopAnimation(nil)
    }

    var isAnimating: Bool {
//        (value(forKeyPath: "animating") as? Bool) ?? false
        false
    }
}

extension NSBezierPath {
    func addLine(to point: NSPoint) {
        line(to: point)
    }

    func addCurve(to endPoint: NSPoint, controlPoint1: NSPoint, controlPoint2: NSPoint) {
        curve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }

    func addQuadCurve(to endPoint: NSPoint, controlPoint: NSPoint) {
        let startPoint = currentPoint
        let controlPoint1 = NSPoint(x: startPoint.x + ((controlPoint.x - startPoint.x) * 2 / 3), y: startPoint.y + ((controlPoint.y - startPoint.y) * 2 / 3))
        let controlPoint2 = NSPoint(x: endPoint.x + ((controlPoint.x - endPoint.x) * 2 / 3), y: endPoint.y + ((controlPoint.y - endPoint.y) * 2 / 3))
        curve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }

    func apply(_ transform: CGAffineTransform) {
        self.transform(using: transform.affineTransform)
    }

    convenience init(roundedRect rect: NSRect, cornerRadius: CGFloat) {
        self.init(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    }
}

extension NSAffineTransform {
    static func makeScale(_ sx: CGFloat, _ sy: CGFloat) -> AffineTransform {
        return AffineTransform(scaleByX: sx, byY: sy)
    }

    static func makeTranslation(_ tx: CGFloat, _ ty: CGFloat) -> AffineTransform {
        return AffineTransform(translationByX: tx, byY: ty)
    }
}

extension AffineTransform {
    init(_ cgAffineTransform: CGAffineTransform) {
        self.init(
            m11: cgAffineTransform.a,
            m12: cgAffineTransform.b,
            m21: cgAffineTransform.c,
            m22: cgAffineTransform.d,
            tX: cgAffineTransform.tx,
            tY: cgAffineTransform.ty
        )
    }
}

extension CGAffineTransform {
    var affineTransform: AffineTransform {
        return AffineTransform(self)
    }
}

extension NSCollectionViewItem {
    var contentView: NSView {
        view
    }
}

#endif

import QuartzCore

extension NSUIView {
    var platformLayer: CALayer? {
        layer
    }
}
