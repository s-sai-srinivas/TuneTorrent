// swift-tools-version: 5.10
import PackageDescription
let package = Package(
    name: "TuneTorrent",
    platforms: [.iOS(.v17)],
    products: [.library(name: "TuneTorrent", targets: ["TuneTorrent"])],
    targets: [
        .target(name: "TuneTorrent", path: "TuneTorrent"),
        // .binaryTarget(name: "LibTorrent", path: "TuneTorrent/Features/Torrent/Services/LibTorrentWrapper/LibTorrent.xcframework")
    ]
)
