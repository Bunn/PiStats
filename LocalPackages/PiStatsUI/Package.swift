// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PiStatsUI",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PiStatsUI",
            targets: ["PiStatsUI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(path: "./PiStatsCore")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PiStatsUI",
            dependencies: ["PiStatsCore"]),
        .testTarget(
            name: "PiStatsUITests",
            dependencies: ["PiStatsUI"]
        ),
    ]
)
