//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Settings",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"],
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Shared"),
        .package(path: "../../DesignSystem"),
        .package(path: "../Onboarding"),
        .package(url: "https://github.com/omaralbeik/Drops", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: ["Domain", "Shared", "DesignSystem", "Onboarding", .product(name: "Drops", package: "Drops")],
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"],
            path: "Tests/SettingsTests",
        ),
    ],
)
