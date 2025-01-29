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
            let allowsImplicitAnimation = context.allowsImplicitAnimation
            context.allowsImplicitAnimation = false
            block()
            context.allowsImplicitAnimation = allowsImplicitAnimation
        }
    }

    func setWantsLayer() {
        wantsLayer = true
    }
    
    #endif
}
