//
//  Package.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Data",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Data",
            targets: ["Data"]
        )
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Networking"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.2")
    ],
    targets: [
        .target(
            name: "Data",
            dependencies: ["Domain", "Networking", "SwiftSoup"]
        ),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data"],
            path: "Tests"
        )
    ]
)
