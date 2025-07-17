// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "ChatLayout",
    platforms: [
        .iOS(.v13)
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
            dependencies: [],
            path: "ChatLayout/Classes",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ChatLayoutTests",
            dependencies: ["ChatLayout"],
            path: "Example/Tests"
        )
    ]
)
