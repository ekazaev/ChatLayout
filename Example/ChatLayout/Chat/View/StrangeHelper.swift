//
// Created by Eugene Kazaev on 03/01/2022.
// Copyright (c) 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

final class ModelItem {
    weak var prev: ModelItem?
    var origin: CGPoint {
        guard let prev = prev else {
            return .zero
        }
        return CGPoint(x: 0, y: prev.origin.y + prev.size.height + 5)
    }

    var frame: CGRect {
        return CGRect(origin: origin, size: size)
    }

    var size: CGSize

    init(prev: ModelItem? = nil, size: CGSize) {
        self.prev = prev
        self.size = size
    }

    func copy() -> ModelItem {
        return ModelItem(size: size)
    }
}

final class ItemStorage<Identifier: Hashable> {
    private(set) var identifiers: [Identifier] = []
    private(set) var models: [ModelItem] = []

    init(identifiers: [Identifier],
         models: [ModelItem]) {
        self.identifiers = identifiers
        self.models = models
    }

    func insert(model: ModelItem, identifier: Identifier, at index: Int) {
        let oldModel = models[index]
        let oldModelPrev = oldModel.prev
        //offsetCompensation += 1000
        models.insert(model, at: index)
        identifiers.insert(identifier, at: index)
        oldModel.prev = model
        model.prev = oldModelPrev
    }

    func delete(identifier: Identifier) {
        guard let index = identifiers.firstIndex(of: identifier) else {
            fatalError()
        }
        let modelToDelete = models[index]
        if index < identifiers.count - 1 {
            let nextModel = models[index + 1]
            nextModel.prev = modelToDelete.prev
        }
        identifiers.remove(at: index)
        models.remove(at: index)
    }

    func modelWithIdentifier(_ identifier: Identifier) -> ModelItem {
        guard let index = identifiers.firstIndex(of: identifier) else {
            fatalError()
        }
        return models[index]
    }

    func copy() -> ItemStorage<Identifier> {
        let newModels = models.reduce(into: [ModelItem](), { result, item in
            let newItem = item.copy()
            newItem.prev = result.last
            result.append(newItem)
        })
        return ItemStorage(identifiers: identifiers, models: newModels)
    }
}

enum ModelState: Hashable, CaseIterable {

    case beforeUpdate

    case afterUpdate

}

final class ItemController<Identifier: Hashable> {

    private(set) var storage: [ModelState: ItemStorage<Identifier>] = [:]

    private(set) var insertedIdentifiers = Set<Identifier>()
    private(set) var deletedIdentifiers = Set<Identifier>()


    init(original: ItemStorage<Identifier>) {
        storage[.beforeUpdate] = original
    }

    func prepareForUpdates(_ updateItems: [ChatLayout_Example.ChangeItem<Identifier>]) {
        let storageAfterUpdate = storage[.beforeUpdate]!.copy()

        updateItems.forEach({ updateItem in
            switch updateItem {
            case let .insert(identifier, at: index):
                storageAfterUpdate.insert(model: ModelItem(size: CGSize(width: 50, height: itemHeight)), identifier: identifier, at: index)
                insertedIdentifiers.insert(identifier)
            case let .delete(identifier):
                storageAfterUpdate.delete(identifier: identifier)
                deletedIdentifiers.insert(identifier)
            }
        })
        storage[.afterUpdate] = storageAfterUpdate
    }

    func finishUpdates() {
        storage[.beforeUpdate] = storage[.afterUpdate]!.copy()
        storage[.afterUpdate] = nil
        insertedIdentifiers = []
        deletedIdentifiers = []
    }
}