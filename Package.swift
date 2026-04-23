// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Premium2048",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "GameCore", targets: ["GameCore"]),
    ],
    targets: [
        .target(
            name: "GameCore",
            path: "Sources/GameCore"
        ),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"],
            path: "Tests/GameCoreTests"
        ),
    ]
)
