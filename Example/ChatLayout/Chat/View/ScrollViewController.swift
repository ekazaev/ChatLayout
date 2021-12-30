//
// Created by Eugene Kazaev on 07/12/2021.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import ChatLayout

final class ScrollViewController: UIViewController {

    lazy var scrollView = LayoutView(frame: UIScreen.main.bounds, engine: SimpleLayoutEngine(), layoutDataSource: self)

    override func loadView() {
        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.backgroundColor = .white
        scrollView.contentSize.height = UIScreen.main.bounds.height * 2
        scrollView.delegate = self
    }

}

extension ScrollViewController: LayoutViewDataSource {
    typealias Identifier = UUID

    typealias Attributes = SimpleLayoutAttributes


    func layoutView(viewForItemAt identifier: UUID) -> UIView {
        let view = UILabel()
        view.backgroundColor = identifier.hashValue % 2 == 0 ? .red : .blue
        view.text = "\(identifier)"
        return view
    }

}
extension ScrollViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.y > scrollView.bounds.height {
//            print("\(#function) - TADA")
//            scrollView.contentSize.height += UIScreen.main.bounds.height * 2
//            scrollView.contentOffset.y -= scrollView.contentOffset.y * 0.5
//        }
    }
}

protocol LayoutViewDataSource: AnyObject {
    associatedtype Identifier: Hashable
    associatedtype Attributes: LayoutAttributes

    func layoutView(viewForItemAt identifier: Identifier) -> UIView
}

/*
final class AnyLayoutViewDataSource<Identifier: Hashable, Attributes: LayoutAttributes>: LayoutViewDataSource {
    private var box: AnyLayoutViewDataSourceBox

    init<DataSource: LayoutViewDataSource>(with dataSource: DataSource) where DataSource.Identifier == Identifier, DataSource.Attributes == Attributes {
        self.box = LayoutViewDataSourceBox(with: dataSource)
    }

    func layoutView(viewForItemAt identifier: Identifier) -> UIView {
        box.layoutView(viewForItemAt: identifier)
    }
}

private protocol AnyLayoutViewDataSourceBox {
    func layoutView<Identifier>(viewForItemAt identifier: Identifier) -> UIView
}

private final class LayoutViewDataSourceBox<DataSource: LayoutViewDataSource>: AnyLayoutViewDataSourceBox {
    private var dataSource: DataSource

    init(with dataSource: DataSource) {
        self.dataSource = dataSource
    }

    func layoutView<Identifier>(viewForItemAt identifier: Identifier) -> UIView {
        guard let typedIdentifier = identifier as? DataSource.Identifier else {
            fatalError("Impossible situation")
        }
        return dataSource.layoutView(viewForItemAt: typedIdentifier)
    }
}
*/
final class LayoutView<Engine: LayoutViewEngine, DataSource: LayoutViewDataSource>: UIScrollView where DataSource.Identifier == Engine.Identifier, DataSource.Attributes == Engine.Attributes {

    private final class ItemView: UIView {
        let identifier: Engine.Identifier
        let attributes: Engine.Attributes
        let customView: UIView

        init(identifier: Engine.Identifier, attributes: Engine.Attributes, customView: UIView) {
            self.identifier = identifier
            self.attributes = attributes
            self.customView = customView
            super.init(frame: attributes.frame)
            addSubview(customView)
            customView.frame = CGRect(origin: .zero, size: attributes.frame.size)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private weak var layoutDataSource : DataSource?
    private let engine: Engine
    private var currentItems = [ItemView]()

    init(frame: CGRect, engine: Engine, layoutDataSource : DataSource) {
        self.engine = engine
        self.layoutDataSource = layoutDataSource
        super.init(frame: frame)
        engine.prepare()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var contentOffset: CGPoint {
        get {
            let offset = super.contentOffset
            //print("\(#function)\(offset)")
            return offset
        }
        set {
            //print("\(#function)\(newValue)")
            super.contentOffset = newValue
        }
    }

    override var contentSize: CGSize {
        get {
            let size = super.contentSize
            //print("\(#function)\(size)")
            return size
        }
        set {
            //print("\(#function)\(newValue)")
            super.contentSize = newValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layoutDataSource = layoutDataSource else {
            return
        }

        var done = false
        let disappearingItems = currentItems.filter({ !$0.attributes.frame.intersects(bounds) })
        repeat {
            let descriptors = engine.descriptors(in: bounds)
            let currentIdentifier = Set(currentItems.map({ $0.identifier }))
            let appearingDescriptors = descriptors.filter({ !currentIdentifier.contains($0.identifier) })

            var finalized = true
            for descriptor in appearingDescriptors {
                let newAttributes = engine.descriptorForAppearingItem(with: descriptor.identifier)
                if newAttributes != descriptor.attributes {
                    let invalidIdentifiers = Set(engine.invalidIdentifiers(in: bounds))
                    if !invalidIdentifiers.isEmpty {
                        currentItems = currentItems.filter({ item in
                            if invalidIdentifiers.contains(item.identifier) {
                                item.removeFromSuperview()
                                return false
                            } else {
                                return true
                            }
                        })
                    }
                    finalized = false
                    break
                }
                let view = layoutDataSource.layoutView(viewForItemAt: descriptor.identifier)
                let item = ItemView(identifier: descriptor.identifier, attributes: newAttributes, customView: view)
                currentItems.append(item)
                addSubview(item)
            }
            if !finalized {
                continue
            }
            done = true
        } while !done

        disappearingItems.forEach({ item in
            _ = engine.descriptorForDisappearingItem(with: item.identifier)
            item.removeFromSuperview()
        })
        currentItems = currentItems.filter({ !disappearingItems.contains($0) })

        let newContentSize = engine.contentSize
        if contentSize != newContentSize {
            contentSize = newContentSize
        }
        // print("\(#function) \(visibleSize) \(bounds)")
    }
}

protocol LayoutAttributes: Equatable {
    var frame: CGRect { get }
    var alpha: CGFloat  { get }
    var zIndex: Int  { get }
    var isHidden: Bool  { get }
}

struct Descriptor<Identifier: Hashable, Attributes: LayoutAttributes> {
    var identifier: Identifier
    var attributes: Attributes

    init(identifier: Identifier, attributes: Attributes) {
        self.identifier = identifier
        self.attributes = attributes
    }
}

protocol LayoutViewEngine {
    associatedtype Identifier: Hashable
    associatedtype Attributes: LayoutAttributes

    var contentSize: CGSize { get }
    func prepare()
    func descriptors(in rect: CGRect) -> [Descriptor<Identifier, Attributes>]

    func invalidIdentifiers(in rect: CGRect) -> [Identifier]

    func descriptorForAppearingItem(with identifier: Identifier) -> Attributes
    func descriptorForDisappearingItem(with identifier: Identifier) -> Attributes
}

struct SimpleLayoutAttributes: LayoutAttributes {
    var frame: CGRect
    var alpha: CGFloat = 0
    var zIndex: Int = 0
    var isHidden: Bool = false
}

let totalItems = 50

final class SimpleLayoutEngine: LayoutViewEngine {
    var contentSize: CGSize {
        guard let lastDescriptor = attributes.last else {
            return .zero
        }
        return CGSize(width: lastDescriptor.frame.maxX, height: lastDescriptor.frame.maxY)
    }
    let identifiers = (0...totalItems).map({ _ in UUID() })
    var attributes: [SimpleLayoutAttributes] = []

    func prepare() {
        attributes = (0...totalItems).map({ index in SimpleLayoutAttributes(frame: CGRect(origin: CGPoint(x: 100, y: index * 100), size: CGSize(width: 50, height: 100))) })
    }

    func descriptors(in rect: CGRect) -> [Descriptor<UUID, SimpleLayoutAttributes>] {
        return identifiers.enumerated().map({ Descriptor(identifier: $0.element, attributes: attributes[$0.offset])}).filter({ $0.attributes.frame.intersects(rect) })
    }

    func invalidIdentifiers(in rect: CGRect) -> [UUID] {
        return []
    }

    func descriptorForAppearingItem(with identifier: UUID) -> SimpleLayoutAttributes {
        print("\(#function) \(identifier)")
        let index = identifiers.firstIndex(where: { $0 == identifier })!
        var descriptor = attributes[index]
        if descriptor.frame.height != 50 {
            let difference = 50 - descriptor.frame.height
            descriptor.frame = CGRect(origin: CGPoint(x: 0, y: descriptor.frame.origin.y), size: CGSize(width: 100, height: 50))
            attributes[index] = descriptor
            for i in (index+1..<attributes.count) {
                var descriptor = attributes[i]
                descriptor.frame = descriptor.frame.offsetBy(dx: 0, dy: difference)
                attributes[i] = descriptor
            }
        }
        return descriptor
    }

    func descriptorForDisappearingItem(with identifier: UUID) -> SimpleLayoutAttributes {
        print("\(#function) \(identifier)")
        let index = identifiers.firstIndex(where: { $0 == identifier })!
        return attributes[index]
    }
}