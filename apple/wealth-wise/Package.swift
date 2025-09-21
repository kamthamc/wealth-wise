// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WealthWise",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WealthWise",
            targets: ["WealthWise"]
        ),
    ],
    dependencies: [
        // No external dependencies yet - keeping it local-first
    ],
    targets: [
        .target(
            name: "WealthWise",
            dependencies: [],
            path: "wealth-wise/Shared",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "WealthWiseTests",
            dependencies: ["WealthWise"],
            path: "wealth-wiseTests"
        ),
    ]
)