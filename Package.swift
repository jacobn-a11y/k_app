// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hallyu",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HallyuCore",
            targets: ["HallyuCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "HallyuCore",
            path: "Hallyu",
            exclude: [
                "Resources/Assets.xcassets",
                "App/HallyuApp.swift",
                "Tests"
            ]
        ),
        .testTarget(
            name: "HallyuTests",
            dependencies: [
                "HallyuCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests"
        ),
        .testTarget(
            name: "HallyuLegacyTests",
            dependencies: ["HallyuCore"],
            path: "Hallyu/Tests"
        )
    ]
)
