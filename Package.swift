// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PCD8544",
    products: [
        .library(
            name: "PCD8544",
            targets: ["PCD8544"]),
    ],
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "PCD8544",
            dependencies: ["SwiftyGPIO"],
            path: ".",
            sources: ["Sources"])
    ]
)
