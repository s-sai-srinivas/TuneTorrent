# LibTorrentWrapper

Vendor `libtorrent-2.0.10-ios-xcframework.zip` here (from https://github.com/arvidn/libtorrent/releases).

Steps:
1. Download release, unzip to LibTorrentWrapper/
2. Add binaryTarget in Package.swift or drag XCFramework to Xcode Frameworks
3. Add bridging header `libtorrent-Bridging-Header.h`

XCFramework is ~120MB signed, BSD license. For sideload IPA, ensure ad-hoc signing strips bitcode.
