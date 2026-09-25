// swift-tools-version: 5.10
import PackageDescription
let package = Package(
    name: "TuneTorrent",
    platforms: [.iOS(.v17)],
    products: [.library(name: "TuneTorrent", targets: ["TuneTorrent"])],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19")
    ],
    targets: [
        .target(
            name: "TuneTorrent",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "TuneTorrent"
        )
    ]
)
