// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CheBiblatexMCP",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CheBiblatexMCPCore", targets: ["CheBiblatexMCPCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", .upToNextMinor(from: "0.11.0")),
        .package(url: "https://github.com/kiki830621/biblatex-apa-swift.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CheBiblatexMCPCore",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "BiblatexAPA", package: "biblatex-apa-swift")
            ],
            path: "Sources/CheBiblatexMCPCore"
        ),
        .executableTarget(
            name: "CheBiblatexMCP",
            dependencies: ["CheBiblatexMCPCore"],
            path: "Sources/CheBiblatexMCP"
        ),
        .testTarget(
            name: "CheBiblatexMCPTests",
            dependencies: ["CheBiblatexMCPCore"],
            path: "Tests/CheBiblatexMCPTests"
        )
    ]
)
