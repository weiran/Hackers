//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"],
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Shared"),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: ["Domain", "Shared"],
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
        ),
    ],
)
