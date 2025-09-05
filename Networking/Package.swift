//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
    targets: [
        .target(
            name: "Networking"
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            path: "Tests"
        )
    ]
)
