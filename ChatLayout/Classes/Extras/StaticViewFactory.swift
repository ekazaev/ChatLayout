//
// ChatLayout
// StaticViewFactory.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// A factory that creates optional contained `UIView`s should conform to this protocol.
public protocol StaticViewFactory {
    /// A type of the view to build.
    associatedtype View: ChatLayout.NSUIView

    /// Factory method that will be called by the corresponding container `UIView`
    /// - Parameter bounds: A bounds rect of the container.
    /// - Returns: Build `UIView` instance.
    static func buildView(within bounds: CGRect) -> View?
}

/// Default extension build the `UIView` using its default constructor.

extension StaticViewFactory where Self: ChatLayout.NSUIView {
    public static func buildView(within bounds: CGRect) -> Self? {
        Self(frame: bounds)
    }
}

/// Use this factory to specify that this view should not be build and should be equal to nil within the container.
public struct VoidViewFactory: StaticViewFactory {
    /// Nil view placeholder type.

    public final class VoidView: ChatLayout.NSUIView {
        @available(*, unavailable, message: "This view can not be instantiated.")
        public required init?(coder aDecoder: NSCoder) {
            fatalError("This view can not be instantiated.")
        }

        @available(*, unavailable, message: "This view can not be instantiated.")
        public override init(frame: CGRect) {
            fatalError("This view can not be instantiated.")
        }

        @available(*, unavailable, message: "This view can not be instantiated.")
        public init() {
            fatalError("This view can not be instantiated.")
        }
    }

    public static func buildView(within bounds: CGRect) -> VoidView? {
        nil
    }
}
