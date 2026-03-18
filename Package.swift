// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hallyu",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "HallyuCore",
            targets: ["HallyuCore"]
        )
    ],
    targets: [
        .target(
            name: "HallyuCore",
            path: "Hallyu",
            exclude: [
                "Resources/Assets.xcassets",
                "Resources/Fonts",
                "Resources/Audio",
                "Resources/HangulStrokeData",
                "App/HallyuApp.swift",
                "App/ContentView.swift",
                "Features"
            ]
        ),
        .testTarget(
            name: "HallyuTests",
            dependencies: ["HallyuCore"],
            path: "Tests"
        )
    ]
)
