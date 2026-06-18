// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "Pensure",
    products: [
        .library(
            name: "Pensure",
            targets: ["Pensure"]
        ),
    ],
    targets: [
        .target(
            name: "Pensure",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ],
    swiftLanguageModes: [.v6]
)
