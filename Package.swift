// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SuperScanner-SwiftUI",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SuperScanner-SwiftUI",
            targets: ["SuperScanner-SwiftUI"]
        ),
    ],
    targets: [
        .target(
            name: "SuperScanner-SwiftUI",
            dependencies: [],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
