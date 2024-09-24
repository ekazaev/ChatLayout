#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias NSUICollectionViewLayoutAttributes = NSCollectionViewLayoutAttributes
public typealias NSUIEdgeInsets = NSEdgeInsets
public typealias NSUICollectionView = NSCollectionView
public typealias NSUICollectionViewLayoutInvalidationContext = NSCollectionViewLayoutInvalidationContext
public typealias NSUICollectionViewLayout = NSCollectionViewLayout
public typealias NSUICollectionViewUpdateItem = NSCollectionViewUpdateItem
public typealias NSUIView = NSView
public typealias NSUILayoutPriority = NSLayoutConstraint.Priority
public typealias NSUIStackView = NSStackView
public typealias NSUIImage = NSImage
public typealias NSUIImageView = NSImageView
#endif

#if canImport(UIKit)
import UIKit
public typealias NSUICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes
public typealias NSUIEdgeInsets = UIEdgeInsets
public typealias NSUICollectionView = UICollectionView
public typealias NSUICollectionViewLayoutInvalidationContext = UICollectionViewLayoutInvalidationContext
public typealias NSUICollectionViewLayout = UICollectionViewLayout
public typealias NSUICollectionViewUpdateItem = UICollectionViewUpdateItem
public typealias NSUIView = UIView
public typealias NSUILayoutPriority = UILayoutPriority
public typealias NSUIStackView = UIStackView
public typealias CollectionReusableView = UICollectionReusableView
public typealias NSUIImage = UIImage
public typealias NSUIImageView = UIImageView
#endif
