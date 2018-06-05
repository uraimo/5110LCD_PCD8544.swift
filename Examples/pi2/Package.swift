import PackageDescription

let package = Package(
    name: "Test5110",
    dependencies: [
        .Package(url: "https://github.com/uraimo/5110LCD_PCD8544.swift.git", majorVersion: 3),
    ]
)
