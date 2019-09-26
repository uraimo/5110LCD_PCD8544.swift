// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Test5110",
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
        .package(url: "https://github.com/uraimo/5110LCD_PCD8544.swift.git",from: "3.0.0")
    ],
    targets: [
        .target(name: "TestServo", 
                dependencies: ["SwiftyGPIO","PCD8544"],
                path: "Sources")
    ]
) 
