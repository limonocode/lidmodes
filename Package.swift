// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LidModes",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LidModes",
            path: "Sources/LidModes"
        ),
    ]
)
