import PackageDescription

let package = Package(
    name: "PCD8544.swift",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git",
                 majorVersion: 1)
    ]
)
