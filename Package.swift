// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "ChatLayout",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ChatLayout",
            targets: ["ChatLayout"]
        ),
        .library(
            name: "ChatLayoutStatic",
            type: .static,
            targets: ["ChatLayout"]
        ),
        .library(
            name: "ChatLayoutDynamic",
            type: .dynamic,
            targets: ["ChatLayout"]
        )
    ],
    targets: [
        .target(
            name: "ChatLayout",
            path: "ChatLayout/Classes"
        ),
        .testTarget(
            name: "ChatLayoutTests",
            dependencies: ["ChatLayout"],
            path: "Example/Tests",
            exclude: ["Info.plist"]
        )
    ],
    swiftLanguageModes: [.v6]
)
