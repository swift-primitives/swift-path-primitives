// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-path-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Path Primitives",
            targets: ["Path Primitives"]
        )
    ],
    dependencies: [
        .package(path: "../swift-string-primitives"),
        .package(path: "../swift-memory-primitives"),
        .package(path: "../swift-identity-primitives"),
    ],
    targets: [
        .target(
            name: "Path Primitives",
            dependencies: [
                .product(name: "String Primitives", package: "swift-string-primitives"),
                .product(name: "Memory Primitives Core", package: "swift-memory-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
            ],
            swiftSettings: [
                .define("PATH_PRIMITIVES_AVAILABLE", .when(platforms: [
                    .macOS, .iOS, .tvOS, .watchOS, .visionOS,
                    .linux, .windows, .android, .openbsd
                ]))
            ]
        ),
        .testTarget(
            name: "Path Primitives Tests",
            dependencies: [
                "Path Primitives",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
