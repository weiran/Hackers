// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]
        )
    ],
    dependencies: [
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: ["Domain"]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        )
    ]
)
