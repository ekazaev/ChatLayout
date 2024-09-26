import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSCollectionView {
    var contentOffset: CGPoint {
        set {
            animator().enclosingScrollView?.contentView.setBoundsOrigin(newValue)
        }
        get {
            enclosingScrollView?.contentView.bounds.origin ?? visibleRect.origin
        }
    }

    var adjustedContentInset: NSEdgeInsets {
        .zero
    }

    private static var isLiveScrollingKey: Void = ()

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
        guard let scrollView = enclosingScrollView else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(willStartLiveScroll), name: NSScrollView.willStartLiveScrollNotification, object: scrollView)
        NotificationCenter.default.addObserver(self, selector: #selector(didEndLiveScroll), name: NSScrollView.didEndLiveScrollNotification, object: scrollView)
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
        return CGRect(x: frame.minX, y: frame.minY, width: visibleRect.width, height: visibleRect.height)
        #endif

        #if canImport(UIKit)
        return frame
        #endif
    }

    var scrollViewBounds: CGRect {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return visibleRect
        #endif

        #if canImport(UIKit)
        return bounds
        #endif
    }
}
