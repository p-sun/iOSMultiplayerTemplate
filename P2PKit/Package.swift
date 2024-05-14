// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "P2PKit",
    platforms: [
        .iOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "P2PKit",
            targets: ["P2PKit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "P2PKit"),
        .testTarget(
            name: "P2PKitTests",
            dependencies: ["P2PKit"]),
    ]
)
