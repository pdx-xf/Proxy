// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Proxy",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Proxy",
            targets: ["Proxy"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Proxy",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ]),
        .testTarget(
            name: "ProxyTests",
            dependencies: ["Proxy"]),
    ]
) 