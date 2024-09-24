#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public typealias NSUIView = NSView
public typealias NSUIViewController = NSViewController
public typealias NSUIStoryboard = NSStoryboard
public typealias NSUIStackView = NSStackView
public typealias NSUIStackViewOrientationOrAxis = NSUserInterfaceLayoutOrientation
public typealias NSUILayoutConstraintOrientationOrAxis = NSLayoutConstraint.Orientation
public typealias NSUILayoutPriority = NSLayoutConstraint.Priority
public typealias NSUIStackViewAlignment = NSLayoutConstraint.Attribute
public typealias NSUIStackViewDistribution = NSUIStackView.Distribution
public typealias NSUIEdgeInsets = NSEdgeInsets
public typealias NSUILayoutGuide = NSLayoutGuide
public typealias NSUIColor = NSColor
public typealias NSUIFont = NSFont
public typealias NSUIBezierPath = NSBezierPath
public typealias NSUIImage = NSImage
public typealias NSUISymbolWeight = NSFont.Weight
public typealias NSUIFontDescriptor = NSFontDescriptor
public typealias NSUIImageView = NSImageView
#endif

#if canImport(UIKit)
import UIKit

public typealias NSUIView = UIView
public typealias NSUIViewController = UIViewController
public typealias NSUIStoryboard = UIStoryboard
public typealias NSUIStackView = UIStackView
public typealias NSUIStackViewOrientationOrAxis = NSLayoutConstraint.Axis
public typealias NSUIStackViewAlignment = NSUIStackView.Alignment
public typealias NSUIStackViewDistribution = NSUIStackView.Distribution
public typealias NSUILayoutPriority = UILayoutPriority
public typealias NSUILayoutConstraintOrientationOrAxis = NSLayoutConstraint.Axis
public typealias NSUIEdgeInsets = UIEdgeInsets
public typealias NSUILayoutGuide = UILayoutGuide
public typealias NSUIColor = UIColor
public typealias NSUIBezierPath = UIBezierPath
public typealias NSUIFont = UIFont
public typealias NSUIImage = UIImage
@available(iOS 13.0, *)
public typealias NSUISymbolWeight = UIImage.SymbolWeight
public typealias NSUIFontDescriptor = UIFontDescriptor
public typealias NSUIImageView = UIImageView
#endif
