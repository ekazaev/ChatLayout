import ChatLayout

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

typealias NSUIView = NSView
typealias NSUIViewController = NSViewController
typealias NSUIStoryboard = NSStoryboard
typealias NSUIStackView = NSStackView
typealias NSUIStackViewOrientationOrAxis = NSUserInterfaceLayoutOrientation
typealias NSUILayoutConstraintOrientationOrAxis = NSLayoutConstraint.Orientation
typealias NSUILayoutPriority = NSLayoutConstraint.Priority
typealias NSUIStackViewAlignment = NSLayoutConstraint.Attribute
typealias NSUIStackViewDistribution = NSUIStackView.Distribution
typealias NSUIEdgeInsets = NSEdgeInsets
typealias NSUILayoutGuide = NSLayoutGuide
typealias NSUIColor = NSColor
typealias NSUIFont = NSFont
typealias NSUIBezierPath = NSBezierPath
typealias NSUIImage = NSImage
typealias NSUISymbolWeight = NSFont.Weight
typealias NSUIFontDescriptor = NSFontDescriptor
typealias NSUIImageView = NSImageView
typealias NSUILabel = NSLabel
typealias NSUICollectionViewCell = NSCollectionViewItem
typealias NSUIContainerCollectionViewCell = ContainerCollectionViewItem
typealias NSUICollectionViewDataSource = NSCollectionViewDataSource
typealias NSUICollectionReusableView = NSView & NSCollectionViewElement
#endif

#if canImport(UIKit)
import UIKit

typealias NSUIView = UIView
typealias NSUIViewController = UIViewController
typealias NSUIStoryboard = UIStoryboard
typealias NSUIStackView = UIStackView
typealias NSUIStackViewOrientationOrAxis = NSLayoutConstraint.Axis
typealias NSUIStackViewAlignment = NSUIStackView.Alignment
typealias NSUIStackViewDistribution = NSUIStackView.Distribution
typealias NSUILayoutPriority = UILayoutPriority
typealias NSUILayoutConstraintOrientationOrAxis = NSLayoutConstraint.Axis
typealias NSUIEdgeInsets = UIEdgeInsets
typealias NSUILayoutGuide = UILayoutGuide
typealias NSUIColor = UIColor
typealias NSUIBezierPath = UIBezierPath
typealias NSUIFont = UIFont
typealias NSUIImage = UIImage
@available(iOS 13.0, *)
typealias NSUISymbolWeight = UIImage.SymbolWeight
typealias NSUIFontDescriptor = UIFontDescriptor
typealias NSUIImageView = UIImageView
typealias NSUILabel = UILabel
typealias NSUICollectionViewCell = UICollectionViewCell
typealias NSUIContainerCollectionViewCell = ContainerCollectionViewCell
typealias NSUICollectionViewDataSource = UICollectionViewDataSource
typealias NSUICollectionReusableView = UICollectionReusableView
#endif
