//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WhatsNew",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "WhatsNew",
            targets: ["WhatsNew"],
        )
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Shared"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "WhatsNew",
            dependencies: ["Domain", "Shared", "DesignSystem"],
        ),
        .testTarget(
            name: "WhatsNewTests",
            dependencies: ["WhatsNew"],
            path: "Tests/WhatsNewTests",
        )
    ],
)
