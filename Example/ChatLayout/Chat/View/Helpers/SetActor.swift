//
// ChatLayout
// SetActor.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation

public final class SetActor<Option: SetAlgebra, ReactionType> {

    public enum Action {

        case onEmpty

        case onChange

        case onInsertion(_ option: Option)

        case onRemoval(_ option: Option)

    }

    public enum ExecutionType {

        case once

        case eternal

    }

    public final class Reaction {

        public let type: ReactionType

        public let action: Action

        public let executionType: ExecutionType

        public let actionBlock: () -> Void

        public init(type: ReactionType, action: Action, executionType: ExecutionType = .once, actionBlock: @escaping () -> Void) {
            self.type = type
            self.action = action
            self.executionType = executionType
            self.actionBlock = actionBlock
        }

    }

    public var options: Option {
        didSet {
            optionsChanged(oldOptions: oldValue)
        }
    }

    public private(set) var reactions: [Reaction]

    public init(options: Option = [], reactions: [Reaction] = []) {
        self.options = options
        self.reactions = reactions
        optionsChanged(oldOptions: [])
    }

    public func add(reaction: Reaction) {
        reactions.append(reaction)
    }

    public func remove(reaction: Reaction) {
        reactions.removeAll(where: { $0 === reaction })
    }

    public func removeAllReactions(where shouldBeRemoved: (Reaction) throws -> Bool) throws {
        try reactions.removeAll(where: shouldBeRemoved)
    }

    public func removeAllReactions() {
        reactions.removeAll()
    }

    private func optionsChanged(oldOptions: Option) {
        let reactions = self.reactions
        let onChangeReactions = reactions.filter {
            guard case .onChange = $0.action else {
                return false
            }
            return true
        }

        onChangeReactions.forEach { reaction in
            reaction.actionBlock()
            if reaction.executionType == .once {
                self.reactions.removeAll(where: { $0 === reaction })
            }
        }

        if options.isEmpty {
            let onEmptyReactions = reactions.filter {
                guard case .onEmpty = $0.action else {
                    return false
                }
                return true
            }
            onEmptyReactions.forEach { reaction in
                reaction.actionBlock()
                if reaction.executionType == .once {
                    self.reactions.removeAll(where: { $0 === reaction })
                }
            }
        }

        let insertedOptions = options.subtracting(oldOptions)
        for option in [insertedOptions] {
            let onEmptyReactions = reactions.filter {
                guard case let .onInsertion(newOption) = $0.action,
                    newOption == option else {
                    return false
                }
                return true
            }
            onEmptyReactions.forEach { reaction in
                reaction.actionBlock()
                if reaction.executionType == .once {
                    self.reactions.removeAll(where: { $0 === reaction })
                }
            }
        }

        let removedOptions = oldOptions.subtracting(options)
        for option in [removedOptions] {
            let onEmptyReactions = reactions.filter {
                guard case let .onRemoval(newOption) = $0.action,
                    newOption == option else {
                    return false
                }
                return true
            }
            onEmptyReactions.forEach { reaction in
                reaction.actionBlock()
                if reaction.executionType == .once {
                    self.reactions.removeAll(where: { $0 === reaction })
                }
            }
        }

    }

}

extension SetActor where ReactionType: Equatable {

    public func removeAllReactions(_ type: ReactionType) {
        reactions.removeAll(where: { $0.type == type })
    }

}
