#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

public class NSLabel: NSTextField {
    public convenience init() {
        self.init(labelWithString: "")
    }

    public var text: String? {
        set {
            stringValue = newValue ?? ""
        }
        get {
            stringValue
        }
    }

    public var numberOfLines: Int {
        set {
            maximumNumberOfLines = newValue
        }
        get {
            maximumNumberOfLines
        }
    }
}

#endif
