#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

extension NSUIView {
    var platformLayer: CALayer? {
        layer
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)

    var effectiveUserInterfaceLayoutDirection: NSUserInterfaceLayoutDirection {
        userInterfaceLayoutDirection
    }

    static func performWithoutAnimation(_ block: () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = false
            block()
        }
    }

    func setWantsLayer() {
        wantsLayer = true
    }
    
    #endif
}
