#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias CollectionViewLayoutAttributes = NSCollectionViewLayoutAttributes
public typealias EdgeInsets = NSEdgeInsets
public typealias CollectionView = NSCollectionView
public typealias CollectionViewLayoutInvalidationContext = NSCollectionViewLayoutInvalidationContext
public typealias CollectionViewLayout = NSCollectionViewLayout
public typealias CollectionViewUpdateItem = NSCollectionViewUpdateItem
#endif

#if canImport(UIKit)
import UIKit
public typealias CollectionViewLayoutAttributes = UICollectionViewLayoutAttributes
public typealias EdgeInsets = UIEdgeInsets
public typealias CollectionView = UICollectionView
public typealias CollectionViewLayoutInvalidationContext = UICollectionViewLayoutInvalidationContext
public typealias CollectionViewLayout = UICollectionViewLayout
public typealias CollectionViewUpdateItem = UICollectionViewUpdateItem
#endif
