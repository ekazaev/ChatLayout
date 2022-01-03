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
    typealias Identifier = String

    typealias Attributes = SimpleLayoutAttributes


    func layoutView(viewForItemAt identifier: String) -> UIView {
        let view = UILabel()
        view.backgroundColor = identifier.hashValue % 2 == 0 ? .red : .blue
        view.text = "Coolaboola \(identifier)"
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
        private(set) var attributes: Engine.Attributes
        let customView: UIView

        init(identifier: Engine.Identifier, attributes: Engine.Attributes, customView: UIView) {
            self.identifier = identifier
            self.attributes = attributes
            self.customView = customView
            super.init(frame: attributes.frame)
            addSubview(customView)
            customView.frame = CGRect(origin: .zero, size: attributes.frame.size)
        }

        func updateAttributes(_ attributes: Engine.Attributes) {
            self.attributes = attributes
            self.frame = attributes.frame
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
        oldSize = frame.size
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

    private var oldSize: CGSize?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layoutDataSource = layoutDataSource else {
            return
        }

        if oldSize != frame.size {
            oldSize = frame.size
            print("\(#function) ROTATION")
        }

        print("\(#function)")
        let scrollViewRepresentation = ScrollViewRepresentation(scrollView: self)
        engine.prepareLayoutSubviews(with: scrollViewRepresentation)

        var done = false
        var disappearingItems: [ItemView] = []
        let currentParameters = ScrollViewParameters(scrollView: self)
        var newParameters = currentParameters
        var itemsToAdd: [ItemView] = []
        repeat {
            print("\(#function) - \(bounds)")
            itemsToAdd = []
            newParameters = engine.scrollViewParameters(with: scrollViewRepresentation, and: currentParameters)

            var viewPort = bounds
            if newParameters != currentParameters {
                print("Modifying view port")
                viewPort = viewPort.offsetBy(dx: newParameters.contentOffset.x - currentParameters.contentOffset.x, dy: newParameters.contentOffset.y - currentParameters.contentOffset.y)
            }
            print("\(#function) viewPort:\(viewPort)")

            let screenDescriptors = engine.descriptors(in: viewPort)
            var finalized = true

            // Items currently on the screen
            let screenDescriptorsIdentifiers = screenDescriptors.compactMap({ $0.identifier })
            let currentlyPresentItems = currentItems.filter({ screenDescriptorsIdentifiers.contains($0.identifier) })
            for item in currentlyPresentItems {
                let newAttributes = engine.attributes(for: item.customView, with: item.identifier)
                if newAttributes != item.attributes {
                    item.updateAttributes(newAttributes)
                    finalized = false
                    print("Current attributes changed \(item.identifier)")
                    break
                }
            }
            if !finalized {
                continue
            }

            // Items that are appearing
            let currentIdentifiers = Set(currentItems.map({ $0.identifier }))
            let appearingDescriptors = screenDescriptors.filter({ !currentIdentifiers.contains($0.identifier) })

            for descriptor in appearingDescriptors {
                let view = layoutDataSource.layoutView(viewForItemAt: descriptor.identifier)

                let newAttributes = engine.attributes(for: view, with: descriptor.identifier)
                if newAttributes != descriptor.attributes {
                    finalized = false
                    print("Attributes changed")
                    break
                }
                UIView.performWithoutAnimation {
                    let item = ItemView(identifier: descriptor.identifier, attributes: newAttributes, customView: view)
                    itemsToAdd.append(item)
                }
            }
            if !finalized {
                continue
            }

            done = true
            disappearingItems = currentItems.filter({ !$0.attributes.frame.intersects(viewPort) })
        } while !done

        engine.commitLayoutSubviews(with: scrollViewRepresentation)

        currentItems = currentItems.filter({ !disappearingItems.contains($0) })
        itemsToAdd.forEach({ item in
            addSubview(item)
        })
        currentItems.append(contentsOf: itemsToAdd)

        if currentParameters != newParameters {
            self.contentSize = newParameters.contentSize
            if self.contentOffset != newParameters.contentOffset {
                print("\(#function) NEW: \(newParameters.contentOffset) | OLD: \(self.contentOffset) ")
                self.contentOffset = newParameters.contentOffset
            }
        }

        CATransaction.setCompletionBlock({ [weak self] in
            print("COMPLETION block")
            guard let self = self else {
                return
            }
            disappearingItems.forEach({ item in
                print("\(item.identifier) disappeared")
                item.removeFromSuperview()
            })
        })
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

struct ScrollViewRepresentation: Equatable {
    let size: CGSize

    init(scrollView: UIScrollView) {
        self.size = scrollView.frame.size
    }
}

struct ScrollViewParameters: Equatable {
    var contentSize: CGSize
    var contentOffset: CGPoint

    init(contentSize: CGSize, contentOffset: CGPoint) {
        self.contentSize = contentSize
        self.contentOffset = contentOffset
    }

    init(scrollView: UIScrollView) {
        self.contentSize = scrollView.contentSize
        self.contentOffset = scrollView.contentOffset
    }
}

protocol LayoutViewEngine {
    associatedtype Identifier: Hashable
    associatedtype Attributes: LayoutAttributes

    // Prepare layout
    func prepare()

    func prepareLayoutSubviews(with representation: ScrollViewRepresentation)
    func commitLayoutSubviews(with representation: ScrollViewRepresentation)

    // View will ask for the attributes in some rect
    func scrollViewParameters(with representation: ScrollViewRepresentation, and currentParameters: ScrollViewParameters) -> ScrollViewParameters

    func descriptors(in rect: CGRect) -> [Descriptor<Identifier, Attributes>]

    func attributes(for view: UIView, with identifier: Identifier) -> Attributes
}

struct SimpleLayoutAttributes: LayoutAttributes {
    var frame: CGRect
    var alpha: CGFloat = 0
    var zIndex: Int = 0
    var isHidden: Bool = false
}

let totalItems = 150

final class SimpleLayoutEngine: LayoutViewEngine {
    private var contentSize: CGSize {
        guard let lastModel = items.last else {
            return .zero
        }
        return CGSize(width: lastModel.frame.maxX, height: lastModel.frame.maxY)
    }

    let identifiers: [String] = (0...totalItems).map({ "\($0)" })
    var items: [ModelItem] = []

    func prepare() {
        self.items = (0...totalItems).reduce(into: [ModelItem](), { result, value in
            let item = ModelItem(prev: result.last, size: CGSize(width: 50, height: 100))
            result.append(item)
        })
    }

    func prepareLayoutSubviews(with representation: ScrollViewRepresentation) {
        currentRepresentation = representation
    }

    func commitLayoutSubviews(with representation: ScrollViewRepresentation) {
        currentRepresentation = representation
        lastRepresentation = representation
        offsetCompensation = 0
    }

    private var offsetCompensation: CGFloat = 0
    private var currentRepresentation: ScrollViewRepresentation?
    private var lastRepresentation: ScrollViewRepresentation?

    func scrollViewParameters(with representation: ScrollViewRepresentation, and currentParameters: ScrollViewParameters) -> ScrollViewParameters {
        if representation != lastRepresentation {
            return ScrollViewParameters(contentSize: contentSize, contentOffset: CGPoint(x: 0, y: contentSize.height - representation.size.height + 30))
        }
        return ScrollViewParameters(contentSize: contentSize, contentOffset: CGPoint(x: 0, y: currentParameters.contentOffset.y + offsetCompensation))
    }

    func descriptors(in rect: CGRect) -> [Descriptor<String, SimpleLayoutAttributes>] {
        return identifiers.enumerated().map({ Descriptor(identifier: $0.element, attributes: SimpleLayoutAttributes(frame: items[$0.offset].frame ))}).filter({ $0.attributes.frame.intersects(rect) })
    }

    func attributes(for view: UIView, with identifier: String) -> SimpleLayoutAttributes {
        var size = view.systemLayoutSizeFitting(.zero, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .fittingSizeLevel)
        if let currentRepresentation = currentRepresentation {
            size.width = currentRepresentation.size.width
        }
        let index = identifiers.firstIndex(where: { $0 == identifier })!
        let model = items[index]
        if model.size != size {
            offsetCompensation += (size.height - model.size.height)
            model.size = size
            items[index] = model
        }
        return SimpleLayoutAttributes(frame: model.frame )
    }
}