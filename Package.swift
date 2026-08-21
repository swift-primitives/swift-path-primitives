// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-path-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Path Primitives",
            targets: ["Path Primitives"]
        ),
        .library(
            name: "Path Primitives Test Support",
            targets: ["Path Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-string-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-tagged-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-ownership-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-error-primitives.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Path Primitives",
            dependencies: [
                .product(name: "String Primitives", package: "swift-string-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
                .product(name: "Error Primitives", package: "swift-error-primitives"),
            ],
            swiftSettings: [
                .define(
                    "PATH_PRIMITIVES_AVAILABLE",
                    .when(platforms: [
                        .macOS, .iOS, .tvOS, .watchOS, .visionOS,
                        .linux, .windows, .android, .openbsd,
                    ])
                )
            ]
        ),
        .target(
            name: "Path Primitives Test Support",
            dependencies: [
                "Path Primitives",
                .product(
                    name: "Tagged Primitives Test Support",
                    package: "swift-tagged-primitives"
                ),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Path Primitives Tests",
            dependencies: [
                "Path Primitives",
                "Path Primitives Test Support",
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
