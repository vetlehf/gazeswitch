// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GazeSwitch",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "GazeSwitch",
            path: "Sources/GazeSwitch",
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/GazeSwitch/Resources/Info.plist"
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
