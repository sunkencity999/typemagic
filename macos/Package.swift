// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TypeMagicKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TypeMagicKit", targets: ["TypeMagicKit"])
    ],
    targets: [
        .target(
            name: "TypeMagicKit",
            path: "Sources/TypeMagicKit"
        ),
        .testTarget(
            name: "TypeMagicKitTests",
            dependencies: ["TypeMagicKit"],
            path: "Tests/TypeMagicKitTests"
        )
    ]
)
