// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Settings",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Shared"),
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: ["Domain", "Shared"]
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"],
            path: "Tests"
        ),
    ]
)