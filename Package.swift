// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "AWGiphyServices",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AWGiphyServices",
            targets: ["AWGiphyServices"]),
    ],
    targets: [
        .target(
            name: "AWGiphyServices",
            dependencies: []),
        .testTarget(
            name: "AWGiphyServicesTests",
            dependencies: ["AWGiphyServices"]),
        .testTarget(
            name: "AWGiphyServicesIntegrationTests",
            dependencies: ["AWGiphyServices"]),
        .executableTarget(
            name: "GiphyDemoApp",
            dependencies: ["AWGiphyServices"],
            path: "Examples/GiphyDemoApp"),
    ]
)
