// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "smartDoor",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.3.3"),
        .package(url: "https://github.com/sroebert/mqtt-nio.git", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "smartDoor",
            dependencies: [
                .product(name: "SwiftyGPIO", package: "SwiftyGPIO"),
                .product(name: "MQTTNIO", package: "mqtt-nio"),
                .product(name: "NIO", package:"swift-nio")
            ]),
        .testTarget(
            name: "smartDoorTests",
            dependencies: ["smartDoor"]),
    ]
)
