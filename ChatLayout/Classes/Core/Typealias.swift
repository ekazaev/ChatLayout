#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias CollectionViewLayoutAttributes = NSCollectionViewLayoutAttributes
public typealias EdgeInsets = NSEdgeInsets
public typealias CollectionView = NSCollectionView
public typealias CollectionViewLayoutInvalidationContext = NSCollectionViewLayoutInvalidationContext
public typealias CollectionViewLayout = NSCollectionViewLayout
public typealias CollectionViewUpdateItem = NSCollectionViewUpdateItem
public typealias View = NSView
public typealias LayoutPriority = NSLayoutConstraint.Priority
public typealias StackView = NSStackView
public typealias Image = NSImage
public typealias ImageView = NSImageView
#endif

#if canImport(UIKit)
import UIKit
public typealias CollectionViewLayoutAttributes = UICollectionViewLayoutAttributes
public typealias EdgeInsets = UIEdgeInsets
public typealias CollectionView = UICollectionView
public typealias CollectionViewLayoutInvalidationContext = UICollectionViewLayoutInvalidationContext
public typealias CollectionViewLayout = UICollectionViewLayout
public typealias CollectionViewUpdateItem = UICollectionViewUpdateItem
public typealias View = UIView
public typealias LayoutPriority = UILayoutPriority
public typealias StackView = UIStackView
public typealias CollectionReusableView = UICollectionReusableView
public typealias Image = UIImage
public typealias ImageView = UIImageView
#endif
