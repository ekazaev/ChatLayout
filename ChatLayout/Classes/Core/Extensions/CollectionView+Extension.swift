import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSCollectionView {
    var contentOffset: CGPoint {
        set {
            enclosingScrollView?.contentView.scroll(to: newValue)
//            animator().scroll(newValue)
        }
        get {
            enclosingScrollView?.contentView.bounds.origin ?? visibleRect.origin
//            visibleRect.origin
        }
    }

    var adjustedContentInset: NSEdgeInsets {
        .zero
    }

    private static var isLiveScrollingKey: Void = ()

    static var isObserveLiveScrollForCollectionView: [NSCollectionView: Bool] = [:]
    
    var isLiveScrolling: Bool {
        set {
            objc_setAssociatedObject(self, &Self.isLiveScrollingKey, NSNumber(booleanLiteral: newValue), .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            if let number = objc_getAssociatedObject(self, &Self.isLiveScrollingKey) as? NSNumber {
                return number.boolValue
            } else {
                return false
            }
        }
    }

    func observeLiveScroll() {
        guard let scrollView = enclosingScrollView, Self.isObserveLiveScrollForCollectionView[self] == nil || Self.isObserveLiveScrollForCollectionView[self] == false else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(willStartLiveScroll), name: NSScrollView.willStartLiveScrollNotification, object: scrollView)
        NotificationCenter.default.addObserver(self, selector: #selector(didEndLiveScroll), name: NSScrollView.didEndLiveScrollNotification, object: scrollView)
        
        Self.isObserveLiveScrollForCollectionView[self] = true
    }

    @objc private func willStartLiveScroll() {
        isLiveScrolling = true
    }

    @objc private func didEndLiveScroll() {
        isLiveScrolling = false
    }
}
#endif

extension NSUICollectionView {
    var platformIndexPathsForVisibleItems: [IndexPath] {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return [IndexPath](indexPathsForVisibleItems())
        #endif

        #if canImport(UIKit)
        return indexPathsForVisibleItems
        #endif
    }

    var scrollViewFrame: CGRect {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return enclosingScrollView?.contentView.frame ?? frame
//        return CGRect(x: frame.origin.x, y: frame.minY, width: bounds.width, height: bounds.height)
        #endif

        #if canImport(UIKit)
        return frame
        #endif
    }

    var scrollViewBounds: CGRect {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return enclosingScrollView?.contentView.bounds ?? visibleRect
        #endif

        #if canImport(UIKit)
        return bounds
        #endif
    }
}
