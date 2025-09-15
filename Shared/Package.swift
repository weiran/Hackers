//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Shared",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "Shared",
            targets: ["Shared"],
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Data"),
        .package(path: "../Networking"),
    ],
    targets: [
        .target(
            name: "Shared",
            dependencies: ["Domain", "Data", "Networking"],
        ),
        .testTarget(
            name: "SharedTests",
            dependencies: ["Shared"],
            path: "Tests/SharedTests",
        ),
    ],
)
