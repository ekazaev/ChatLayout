//
// Created by Eugene Kazaev on 07/12/2021.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import ChatLayout

final class ScrollViewController: UIViewController {

    lazy var scrollView = LayoutView(frame: UIScreen.main.bounds, engine: SimpleLayoutEngine(), layoutDataSource: self)

    var texts: [String: String] = [:]

    override func loadView() {
        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(ScrollViewController.reload))

        scrollView.backgroundColor = .white
        scrollView.contentSize.height = UIScreen.main.bounds.height * 2
        scrollView.delegate = self
    }

    @objc private func reload() {
        /*
        for i in 0...5 {
            UIView.animate(withDuration: 0.25, animations: {
                self.scrollView.performBatchUpdates([.insert("1.\(i) \(UUID().uuidString)", at: 1)])
                self.scrollView.layoutSubviews()
            })
        }
         */
        self.scrollView.performBatchUpdates([.delete(self.texts.keys.first!)])
    }
}

extension ScrollViewController: LayoutViewDataSource {
    typealias Identifier = String

    typealias Attributes = SimpleLayoutAttributes


    func layoutView(viewForItemAt identifier: String) -> LayoutableView {
        let view = scrollView.dequeuView() as! DefaultLayoutableView // DefaultLayoutableView()
        view.backgroundColor = identifier.hashValue % 2 == 0 ? .red : .blue

        let text: String
        switch texts[identifier] {
        case let .some(savedText):
            text = savedText
        case .none:
            text = TextGenerator.getString(of: 20)
            texts[identifier] = text
        }
        view.label.text = "\(identifier) - \(text)"
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

    func layoutView(viewForItemAt identifier: Identifier) -> LayoutableView
}

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
            customView.alpha = attributes.alpha
        }

        func updateAttributes(_ attributes: Engine.Attributes) {
            self.attributes = attributes
            //commitAttributeUpdate()
        }

        // Questionable decision!!!
        func commitAttributeUpdate() {
            self.frame = attributes.frame
            customView.frame = CGRect(origin: .zero, size: attributes.frame.size)
            customView.alpha = attributes.alpha
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private weak var layoutDataSource : DataSource?
    private let engine: Engine
    private var currentItems = [ItemView]()

    private var dequeu = Set<DefaultLayoutableView>()

    init(frame: CGRect, engine: Engine, layoutDataSource : DataSource) {
        self.engine = engine
        self.layoutDataSource = layoutDataSource
        super.init(frame: frame)
        oldSize = frame.size
        engine.setup(WeakScrollViewRepresentation(scrollView: self))
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

    func dequeuView() -> LayoutableView {
        guard let view = dequeu.first else {
            print("CREATED NEW")
            return DefaultLayoutableView(frame: CGRect.zero)
        }
        dequeu.remove(view)
        print("DEQUEUED")
        return view
    }

    func performBatchUpdates(_ updateItems: [ChangeItem<Engine.Identifier>]) {
        UIView.animate(withDuration: 0.25, animations: {
            self.engine.prepareForUpdates(updateItems)
            self.layoutSubviews()
            self.engine.finalizeUpdates()
        })
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

        print("\(#function) START")
        print("\(#function) contentSize: \(contentSize) contentOffset:\(contentOffset)")

        engine.prepareLayoutSubviews()

        var done = false
        var disappearingItems: [ItemView] = []
        let currentParameters = ScrollViewParameters(scrollView: self)
        var newParameters = currentParameters

        var currentlyPresentItems:[ItemView] = []
        var itemsToAdd: [(identifier: Engine.Identifier, initialAttributes: Engine.Attributes, customView: UIView, finalAttributes: Engine.Attributes)] = []

        var localCustomViews: [Engine.Identifier: DefaultLayoutableView] = [:]
        repeat {
            print("\(#function) - \(bounds) CYCLE START")
            itemsToAdd = []

            // Getting final parameters of scrollView
            newParameters = engine.scrollViewParameters(with: currentParameters)

            // Getting all visible items in a visible rect
            var viewPort = bounds
            if newParameters != currentParameters {
                print("Modifying view port")
                viewPort = viewPort.offsetBy(dx: newParameters.contentOffset.x - currentParameters.contentOffset.x, dy: newParameters.contentOffset.y - currentParameters.contentOffset.y)
            }
            print("\(#function) viewPort:\(viewPort)")

            let screenDescriptors = engine.descriptors(in: viewPort)

            // Starting update cycle
            var finalized = true

            // Items currently on the screen
            let screenDescriptorsIdentifiers = screenDescriptors.compactMap({ $0.identifier })
            currentlyPresentItems = currentItems.filter({ screenDescriptorsIdentifiers.contains($0.identifier) })
            for item in currentlyPresentItems {
                let newAttributes = engine.preferredAttributes(for: item.customView, with: item.identifier)
                if newAttributes != item.attributes {
                    item.updateAttributes(newAttributes)
                    finalized = false
                    print("Current attributes changed \(item.identifier) \(newAttributes)")
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
                let view: UIView
                if let localView = localCustomViews[descriptor.identifier] {
                    view = localView
                } else {
                    view = layoutDataSource.layoutView(viewForItemAt: descriptor.identifier)
                    localCustomViews[descriptor.identifier] = (view as! DefaultLayoutableView)
                }
                localCustomViews[descriptor.identifier] = (view as! DefaultLayoutableView)
                let newAttributes = engine.preferredAttributes(for: view, with: descriptor.identifier)
                if newAttributes != descriptor.attributes {
                    finalized = false
                    print("Appeared Attributes changed \(descriptor.identifier) \(newAttributes)")
                    break
                }
                let initialAttributes = engine.initialAttributesForAppearingViewWith(descriptor.identifier) ?? newAttributes
                itemsToAdd.append((identifier: descriptor.identifier, initialAttributes: initialAttributes, customView: view, finalAttributes: newAttributes))
            }
            if !finalized {
                continue
            }

            done = true
            disappearingItems = currentItems.filter({ !$0.attributes.frame.intersects(viewPort) || !screenDescriptorsIdentifiers.contains($0.identifier) })
        } while !done

        engine.commitLayoutSubviews()

        currentlyPresentItems.forEach({ item in
            item.commitAttributeUpdate()
        })

        currentItems = currentItems.filter({ !disappearingItems.contains($0) })

        /// TODO: Find out why! Most likely because more disappeared.
//        if currentItems.count != currentlyPresentItems.count {
//            assertionFailure()
//        }

        itemsToAdd.forEach({ itemToAdd in
            var item: ItemView!
            UIView.performWithoutAnimation {
                print("APPEARED \(itemToAdd.identifier) \(itemToAdd.initialAttributes) - \(itemToAdd.finalAttributes)")
                /*
                // Actually if you add something and then change content offset/content size it wont appear at this coordinates.
                // That helps to compensate it but probably should be in the engine intead/
                var initialAttributes = itemToAdd.initialAttributes as! SimpleLayoutAttributes
                initialAttributes.frame = initialAttributes.frame.offsetBy(dx: 0, dy: currentParameters.contentOffset.y - newParameters.contentOffset.y)
                */
                item = ItemView(identifier: itemToAdd.identifier, attributes: itemToAdd.initialAttributes, customView: itemToAdd.customView)
                addSubview(item)
            }
            print("\(item.identifier) appeared")
            if item.attributes != itemToAdd.finalAttributes {
                item.updateAttributes(itemToAdd.finalAttributes)
                item.commitAttributeUpdate()
            }
            currentItems.append(item)
        })

        if currentParameters != newParameters {
            if self.contentSize != newParameters.contentSize {
                print("contentSize: \(#function) NEW: \(newParameters.contentSize) | OLD: \(self.contentSize) ")
                self.contentSize = newParameters.contentSize
            }
            if self.contentOffset != newParameters.contentOffset {
                print("contentOffset: \(#function) NEW: \(newParameters.contentOffset) | OLD: \(self.contentOffset) ")
                self.contentOffset = newParameters.contentOffset
            }
        }

        disappearingItems.forEach({ item in
            guard let attributes = engine.finalAttributesForDisappearingViewWith(item.identifier) else {
                return
            }
            item.updateAttributes(attributes)
            item.commitAttributeUpdate()
        })

        CATransaction.setCompletionBlock({ [weak self] in
            print("COMPLETION block")
            guard let self = self else {
                return
            }
            disappearingItems.forEach({ item in
                print("\(item.identifier) disappeared")
                item.removeFromSuperview()
                if let dv = item.customView as? DefaultLayoutableView {
                    print("SAVED")
                    self.dequeu.insert(dv)
                }
            })
        })
        print("\(#function) FINISH")
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

protocol ScrollViewRepresentation {
    var size: CGSize { get }
    var contentOffset: CGPoint { get }
    var contentSize: CGSize { get }
    var visibleRect: CGRect { get }
}

struct WeakScrollViewRepresentation: ScrollViewRepresentation, Equatable {
    var size: CGSize {
        return scrollView?.frame.size ?? .zero
    }

    var contentOffset: CGPoint {
        return scrollView?.contentOffset ?? .zero
    }

    var contentSize: CGSize {
        return scrollView?.contentSize ?? .zero
    }

    var visibleRect: CGRect {
        guard let scrollView = scrollView else {
            return .zero
        }
        return CGRect(x: scrollView.adjustedContentInset.left,
                y: scrollView.contentOffset.y + scrollView.adjustedContentInset.top,
                width: scrollView.bounds.width - scrollView.adjustedContentInset.left - scrollView.adjustedContentInset.right,
                height: scrollView.bounds.height - scrollView.adjustedContentInset.top - scrollView.adjustedContentInset.bottom)
    }

    weak var scrollView: UIScrollView?

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }
}

struct ScrollViewRepresentationSnapshot: ScrollViewRepresentation, Equatable {
    var size: CGSize

    var contentOffset: CGPoint

    var contentSize: CGSize

    var visibleRect: CGRect

    init(representation: ScrollViewRepresentation) {
        self.size = representation.size
        self.contentOffset = representation.contentOffset
        self.contentSize = representation.contentSize
        self.visibleRect = representation.visibleRect
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

enum ChangeItem<Identifier: Hashable> {
    case insert(Identifier, at: Int)
    case delete(Identifier)
}

protocol LayoutViewEngine {
    associatedtype Identifier: Hashable
    associatedtype Attributes: LayoutAttributes

    func setup(_ representation: ScrollViewRepresentation)

    // Prepare layout
    func prepare()

    func prepareLayoutSubviews()
    func commitLayoutSubviews()

    func prepareForUpdates(_ updateItems: [ChangeItem<Identifier>])
    func finalizeUpdates()

    // View will ask for the attributes in some rect
    func scrollViewParameters(with currentParameters: ScrollViewParameters) -> ScrollViewParameters

    func descriptors(in rect: CGRect) -> [Descriptor<Identifier, Attributes>]

    func preferredAttributes(for view: UIView, with identifier: Identifier) -> Attributes

    func attributes(with identifier: Identifier) -> Attributes

    func initialAttributesForAppearingViewWith( _ identifier: Identifier) -> Attributes?
    func finalAttributesForDisappearingViewWith( _ identifier: Identifier) -> Attributes?
}

struct SimpleLayoutAttributes: LayoutAttributes {
    var frame: CGRect
    var alpha: CGFloat = 1
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

    var identifiers: [String] = (0...totalItems).map({ "\($0)" })
    var items: [ModelItem] = []

    private var representation: ScrollViewRepresentation!

    func setup(_ representation: ScrollViewRepresentation) {
        self.representation = representation
    }

    func prepare() {
        self.items = (0...totalItems).reduce(into: [ModelItem](), { result, value in
            let item = ModelItem(prev: result.last, size: CGSize(width: 50, height: 1000))
            result.append(item)
        })
    }

    func prepareLayoutSubviews() {
    }

    func commitLayoutSubviews() {
        lastRepresentation = ScrollViewRepresentationSnapshot(representation: representation)
        offsetCompensation = 0
    }

    private var offsetCompensation: CGFloat = 0
    private var lastRepresentation: ScrollViewRepresentation?

    func scrollViewParameters(with currentParameters: ScrollViewParameters) -> ScrollViewParameters {
        if representation.size != lastRepresentation?.size {
            return ScrollViewParameters(contentSize: contentSize, contentOffset: CGPoint(x: 0, y: contentSize.height - representation.size.height + 30))
        }
        return ScrollViewParameters(contentSize: contentSize, contentOffset: CGPoint(x: 0, y: currentParameters.contentOffset.y + offsetCompensation))
    }

    func descriptors(in rect: CGRect) -> [Descriptor<String, SimpleLayoutAttributes>] {
        return identifiers.enumerated().map({ Descriptor(identifier: $0.element, attributes: SimpleLayoutAttributes(frame: items[$0.offset].frame ))}).filter({ $0.attributes.frame.intersects(rect) })
    }

    func preferredAttributes(for view: UIView, with identifier: String) -> SimpleLayoutAttributes {
        var size = view.systemLayoutSizeFitting(CGSize(width: representation.size.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        size.width = representation.size.width
        let index = identifiers.firstIndex(where: { $0 == identifier })!
        let model = items[index]
        if model.size != size {
            // offsetCompensation += (size.height - model.size.height)
            model.size = size
            items[index] = model
        }
        return SimpleLayoutAttributes(frame: model.frame )
    }

    private var isAnimatedUpdates = false

    func prepareForUpdates(_ updateItems: [ChatLayout_Example.ChangeItem<String>]) {
        isAnimatedUpdates = true
        updateItems.forEach({ updateItem in
            switch updateItem {
            case let .insert(newIdentifier, at: index):
                let oldModel = items[index]
                let oldModelPrev = oldModel.prev
                let newModel = ModelItem(size: CGSize(width: 50, height: 1000))
                //offsetCompensation += 1000
                items.insert(newModel, at: index)
                identifiers.insert(newIdentifier, at: index)
                oldModel.prev = newModel
                newModel.prev = oldModelPrev
            case let .delete(identifier):
                guard let index = identifiers.firstIndex(of: identifier) else {
                    fatalError()
                }
                let modelToDelete = items[index]
                if index < identifiers.count - 1 {
                    let nextModel = items[index + 1]
                    nextModel.prev = modelToDelete.prev
                }
                identifiers.remove(at: index)
                items.remove(at: index)
            }
        })
    }

    func finalizeUpdates() {
        isAnimatedUpdates = false
    }

    func attributes(with identifier: String) -> SimpleLayoutAttributes {
        let index = identifiers.firstIndex(where: { $0 == identifier })!
        let model = items[index]
        model.size.width = representation.size.width
        return SimpleLayoutAttributes(frame: model.frame )
    }

    func initialAttributesForAppearingViewWith(_ identifier: String) -> SimpleLayoutAttributes? {
        var attributes = attributes(with: identifier)
        attributes.alpha = 0
        if let lastRepresentation = lastRepresentation {
            attributes.frame.size.width = lastRepresentation.size.width
        }
        return attributes
    }

    func finalAttributesForDisappearingViewWith(_ identifier: String) -> SimpleLayoutAttributes? {
        var attributes = attributes(with: identifier)
        attributes.alpha = 0
        return attributes
    }
}


protocol LayoutableView: UIView {

    func preferredLayoutAttributesFitting<LA: LayoutAttributes>(_ layoutAttributes: LA) -> LA
}

final class DefaultLayoutableView: UIView, LayoutableView {

    lazy var label = UILabel(frame: frame)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable, message: "Use init(reuseIdentifier:) instead")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func preferredLayoutAttributesFitting<LA: LayoutAttributes>(_ layoutAttributes: LA) -> LA {
        guard let layoutAttributes = layoutAttributes as? SimpleLayoutAttributes else {
            return layoutAttributes
        }
        let size = self.systemLayoutSizeFitting(.zero, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .fittingSizeLevel)
        if layoutAttributes.frame.size != size {
            var layoutAttributes = layoutAttributes
            layoutAttributes.frame = CGRect(origin: layoutAttributes.frame.origin, size: size)
            return layoutAttributes as! LA
        }
        return layoutAttributes as! LA
    }

    private func setupSubviews() {
        addSubview(label)

        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        label.insetsLayoutMarginsFromSafeArea = false
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor).isActive = true
    }
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