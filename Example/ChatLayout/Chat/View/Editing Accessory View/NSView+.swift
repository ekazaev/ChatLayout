#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSView {
    static func animate(withDuration duration: TimeInterval, block: () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            block()
        }
    }
    static func performWithoutAnimation(_ block: () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = false
            block()
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
        get{
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

extension NSUIView {
    var platformLayer: CALayer? {
        layer
    }
}

extension NSCollectionView {
    func dequeueReusableCell(withReuseIdentifier reuseIdentifier: String, for indexPath: IndexPath) -> NSUICollectionViewCell {
        makeItem(withIdentifier: .init(reuseIdentifier), for: indexPath)
    }
    func register(_ itemClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        register(itemClass, forItemWithIdentifier: .init(identifier))
    }
    func register(_ viewClass: AnyClass?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        register(viewClass, forSupplementaryViewOfKind: kind, withIdentifier: .init(identifier))
    }
}


#endif
