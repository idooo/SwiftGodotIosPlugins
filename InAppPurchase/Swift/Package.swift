// swift-tools-version: 5.9.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InAppPurchase",
    platforms: [.iOS(.v17),(.macOS(.v14))],
    products: [
        .library(
            name: "InAppPurchase",
            type: .dynamic,
            targets: ["InAppPurchase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "48112dd50fffe01f0af78e445a16991ecdc6bc94")
    ],
    targets: [
        .target(
            name: "InAppPurchase",
            dependencies: [
                "SwiftGodot",
            ],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
        ),
    ]
)
