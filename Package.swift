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
                // SwiftUI views excluded from SPM library target
                "Features/Hangul/StrokeOrderView.swift",
                "Features/Hangul/JamoDetailView.swift",
                "Features/Hangul/HangulLessonView.swift",
                "Features/Hangul/SyllableBlockBuilderView.swift",
                "Features/Hangul/SpotInTheWildView.swift",
                "Features/Onboarding",
                "Features/MediaLibrary",
                "Features/MediaLesson",
                "Features/Pronunciation",
                "Features/Review",
                "Features/Progress",
                "Features/DailyPlan",
                "Features/Settings",
            ]
        ),
        .testTarget(
            name: "HallyuTests",
            dependencies: ["HallyuCore"],
            path: "Tests"
        )
    ]
)
