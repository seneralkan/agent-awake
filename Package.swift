// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AgentAwake",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "AgentAwake", path: "Sources/AgentAwake")
    ]
)
