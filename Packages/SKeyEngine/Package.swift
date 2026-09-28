// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SKeyEngine",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SKeyEngine", targets: ["SKeyEngine"])
    ],
    targets: [
        .target(name: "SKeyEngine"),
        .testTarget(name: "SKeyEngineTests", dependencies: ["SKeyEngine"]),
    ]
)
