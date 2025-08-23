// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Feed",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Feed",
            targets: ["Feed"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Shared"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "Feed",
            dependencies: ["Domain", "Shared", "DesignSystem"]
        ),
        .testTarget(
            name: "FeedTests",
            dependencies: ["Feed"],
            path: "Tests"
        )
    ]
)
