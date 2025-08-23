//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Comments",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Comments",
            targets: ["Comments"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Shared"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "Comments",
            dependencies: ["Domain", "Shared", "DesignSystem"]
        ),
        .testTarget(
            name: "CommentsTests",
            dependencies: ["Comments", "Domain", "Shared"]
        )
    ]
)
