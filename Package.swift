// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwErl",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
        .watchOS(.v7),
        .macCatalyst(.v15),
        .tvOS(.v15)
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwErl",
            targets: ["SwErl"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwErl",
            dependencies: [.product(name: "Logging", package: "swift-log"),"BigInt"]),
        .testTarget(
            name: "SwErlTests",
            dependencies: ["SwErl"]),
        .testTarget(
            name: "SwErlStatemTests",
            dependencies: ["SwErl"]),
        .testTarget(
            name: "SwErlGenServerTests",
            dependencies: ["SwErl"]),
        .testTarget(
            name: "SwErlEventManagerTests",
            dependencies: ["SwErl"]),
        .testTarget(
            name: "SwErlNodeTests",
            dependencies: ["SwErl"]),
    ]
)
