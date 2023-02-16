// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Harmony-Drive",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .macOS(.v12)
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
        .package(url: "https://github.com/JoeMatt/Roxas.git", from: "1.2.0"),
        .package(url: "https://github.com/JoeMatt/Harmony.git", from: "1.2.4")
        //		.package(path: "../Harmony")
    ],
    targets: [
        .target(
            name: "Harmony-Drive",
            dependencies: [
                "Harmony",
                .product(name: "GoogleAPIClientForRESTCore", package: "google-api-objectivec-client-for-rest"),
                .product(name: "GoogleAPIClientForREST_Drive", package: "google-api-objectivec-client-for-rest"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS", condition: .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS]))
            ]
        ),
        .executableTarget(
            name: "Harmony-DriveExample",
            dependencies: [
                "Harmony-Drive",
                .product(name: "HarmonyExample", package: "Harmony"),
                .product(name: "RoxasUI", package: "Roxas", condition: .when(platforms: [.iOS, .tvOS, .macCatalyst])),
                .product(name: "GoogleAPIClientForRESTCore", package: "google-api-objectivec-client-for-rest"),
                .product(name: "GoogleAPIClientForREST_Drive", package: "google-api-objectivec-client-for-rest"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("Cocoa", .when(platforms: [.macOS])),
                .linkedFramework("CoreData")
            ]
        ),
        .testTarget(
            name: "Harmony-DriveTests",
            dependencies: ["Harmony"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
