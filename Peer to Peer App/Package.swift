// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MuPeer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MuPeer",
            targets: ["MuPeer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/musesum/MuFlo.git", .branch("main")),
        .package(url: "https://github.com/musesum/MuExtensions.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "MuPeer",
            dependencies: [
                .product(name: "MuExtensions", package: "MuExtensions"),
                .product(name: "MuFlo", package: "MuFlo"),
            ]),
        .testTarget(
            name: "MuPeerTests",
            dependencies: ["MuPeer"]),
    ]
)
