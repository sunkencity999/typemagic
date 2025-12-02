// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TypeMagicMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TypeMagicMac", targets: ["TypeMagicMac"])
    ],
    targets: [
        .executableTarget(
            name: "TypeMagicMac",
            path: "Sources/TypeMagicMac"
        ),
        .testTarget(
            name: "TypeMagicMacTests",
            dependencies: ["TypeMagicMac"],
            path: "Tests/TypeMagicMacTests"
        )
    ]
)
