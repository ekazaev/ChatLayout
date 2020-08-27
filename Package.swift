// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ChatLayout",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ChatLayout",
            targets: ["ChatLayout"]
        )
    ],
    targets: [
        .target(
            name: "ChatLayout",
            dependencies: [],
            path: "ChatLayout/Classes"
        ),
        .testTarget(
            name: "ChatLayoutTests",
            dependencies: ["ChatLayout"],
            path: "Example/Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
