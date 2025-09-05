//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Onboarding",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Shared"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "Onboarding",
            dependencies: ["Domain", "Shared", "DesignSystem"]
        ),
        .testTarget(
            name: "OnboardingTests",
            dependencies: ["Onboarding"],
            path: "Tests"
        )
    ]
)
