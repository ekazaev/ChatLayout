#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

class NSLabel: NSTextField {
    convenience init() {
        self.init(labelWithString: "")
    }
    
    var text: String? {
        set {
            stringValue = newValue ?? ""
        }
        get {
            stringValue
        }
    }
    
    var numberOfLines: Int {
        set {
            maximumNumberOfLines = newValue
        }
        get {
            maximumNumberOfLines
        }
    }
}

#endif
