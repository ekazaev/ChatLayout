import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSCollectionView {
    var contentOffset: CGPoint {
        set {
            guard let scrollView = enclosingScrollView else { return }
            scrollView.documentView?.scroll(newValue)
        }
        get {
            guard let scrollView = enclosingScrollView else { return .zero }
            return scrollView.documentVisibleRect.origin
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

    func layoutIfNeeded() {
        layoutSubtreeIfNeeded()
    }

    func setNeedsLayout() {
        needsLayout = true
    }
}
#endif

extension CollectionView {
    var platformIndexPathsForVisibleItems: [IndexPath] {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return [IndexPath](indexPathsForVisibleItems())
        #endif

        #if canImport(UIKit)
        return indexPathsForVisibleItems
        #endif
    }
}
