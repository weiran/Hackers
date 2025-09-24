//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Authentication",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Authentication",
            targets: ["Authentication"],
        )
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Shared"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "Authentication",
            dependencies: ["Domain", "Shared", "DesignSystem"],
        ),
        .testTarget(
            name: "AuthenticationTests",
            dependencies: ["Authentication"],
            path: "Tests/AuthenticationTests"
        )
    ],
)
