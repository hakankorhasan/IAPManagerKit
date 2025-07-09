// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "IAPManagerKit",
    platforms: [
        .iOS(.v13),         
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "IAPManagerKit", targets: ["IAPManagerKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "IAPManagerKit",
            dependencies: []),
        .testTarget(
            name: "IAPManagerKitTests",
            dependencies: ["IAPManagerKit"]),
    ]
)

