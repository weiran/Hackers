//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "Authentication", targets: ["Authentication"]),
        .library(name: "Comments", targets: ["Comments"]),
        .library(name: "Feed", targets: ["Feed"]),
        .library(name: "Settings", targets: ["Settings"]),
        .library(name: "WhatsNew", targets: ["WhatsNew"])
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Shared"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "Authentication",
            dependencies: ["Domain", "Shared", "DesignSystem"],
            path: "Authentication/Sources/Authentication"
        ),
        .testTarget(
            name: "AuthenticationTests",
            dependencies: ["Authentication"],
            path: "Authentication/Tests/AuthenticationTests"
        ),
        .target(
            name: "Comments",
            dependencies: ["Domain", "Shared", "DesignSystem"],
            path: "Comments/Sources/Comments"
        ),
        .testTarget(
            name: "CommentsTests",
            dependencies: ["Comments", "Domain", "Shared"],
            path: "Comments/Tests/CommentsTests"
        ),
        .target(
            name: "Feed",
            dependencies: ["Domain", "Shared", "DesignSystem"],
            path: "Feed/Sources/Feed"
        ),
        .testTarget(
            name: "FeedTests",
            dependencies: ["Feed"],
            path: "Feed/Tests/FeedTests"
        ),
        .target(
            name: "Settings",
            dependencies: ["Domain", "Shared", "DesignSystem", "Authentication", "WhatsNew"],
            path: "Settings/Sources/Settings"
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"],
            path: "Settings/Tests/SettingsTests"
        ),
        .target(
            name: "WhatsNew",
            dependencies: ["Domain", "Shared", "DesignSystem"],
            path: "WhatsNew/Sources/WhatsNew"
        ),
        .testTarget(
            name: "WhatsNewTests",
            dependencies: ["WhatsNew"],
            path: "WhatsNew/Tests/WhatsNewTests"
        )
    ]
)
