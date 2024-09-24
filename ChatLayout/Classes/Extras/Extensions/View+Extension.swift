#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

extension View {
    var platformLayer: CALayer? {
        layer
    }

    #if canImport(AppKit)

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
