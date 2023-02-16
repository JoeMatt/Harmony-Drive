// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Harmony-Drive",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "Harmony-Drive",
            targets: ["Harmony-Drive"]
        ),
        .library(
            name: "Harmony-Drive-Dynamic",
            type: .dynamic,
            targets: ["Harmony-Drive"]
        ),
        .library(
            name: "Harmony-Drive-Static",
            type: .static,
            targets: ["Harmony-Drive"]
        ),
		.executable(name: "Harmony-DriveExample", targets: ["Harmony-DriveExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/google/google-api-objectivec-client-for-rest.git", from: "3.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
//         .package(url: "https://github.com/JoeMatt/Harmony.git", from: "1.1.1")
        .package(path: "../Harmony")
    ],
    targets: [
        .target(
            name: "Harmony-DriveExample",
            dependencies: [
                "Harmony",
				"HarmonyExample",
                .product(name: "GoogleAPIClientForRESTCore", package: "google-api-objectivec-client-for-rest"),
                .product(name: "GoogleAPIClientForREST_Drive", package: "google-api-objectivec-client-for-rest"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ]
        ),
        .testTarget(
            name: "Harmony-DriveTests",
            dependencies: ["Harmony"]
        )
    ]
)
