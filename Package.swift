// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ShimmerX",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ShimmerX",
            targets: ["ShimmerX"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ShimmerX",
            path: "Sources"
        )
    ]
)
