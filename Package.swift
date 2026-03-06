// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GazeSwitch",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "GazeSwitch",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/GazeSwitch",
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/GazeSwitch/Resources/Info.plist",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@loader_path/../Frameworks"
                ])
            ]
        ),
        .testTarget(
            name: "GazeSwitchTests",
            dependencies: ["GazeSwitch"],
            path: "Tests/GazeSwitchTests"
        )
    ]
)
