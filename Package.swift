// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MDFileViewer",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MDFileViewer", targets: ["MDFileViewer"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "MDFileViewer",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            exclude: ["Resources"]
        )
    ]
)
