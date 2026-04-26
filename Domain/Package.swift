//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Domain",
            targets: ["Domain"],
        )
    ],
    dependencies: [
        .package(path: "../Data"),
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "Domain",
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                .product(name: "Data", package: "Data"),
                .product(name: "Networking", package: "Networking")
            ],
            path: "Tests/DomainTests",
        )
    ],
)
