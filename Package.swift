// swift-tools-version:5.5
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
    dependencies: [],
    targets: [
        .target(
            name: "SuperScanner-SwiftUI",
            dependencies: [],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
