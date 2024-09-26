#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

public class NSLabel: NSTextField {
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isEditable = false
        drawsBackground = false
        isBordered = false
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
