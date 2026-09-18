import XCTest
@testable import TuneTorrent

// MARK: - MediaLibraryServiceTests
final class MediaLibraryServiceTests: XCTestCase {
    func testMockReturnsEmpty() async {
        let s = MockMediaLibraryService()
        let songs = await s.fetchAllSongs()
        XCTAssertEqual(songs.count, 0)
    }
}

// MARK: - StorageAnalyzerTests
final class StorageAnalyzerTests: XCTestCase {
    func testBreakdownComputes() async {
        let svc = StorageAnalyzerService()
        let tmp = FileManager.default.temporaryDirectory
        let b = await svc.breakdown(root: tmp)
        XCTAssertGreaterThanOrEqual(b.free, 0)
    }
    func testLargeFiles() async {
        let svc = StorageAnalyzerService()
        let tmp = FileManager.default.temporaryDirectory
        let large = await svc.largeFiles(in: tmp, threshold: 100*1024*1024)
        XCTAssertNotNil(large)
    }
}

// MARK: - TorrentServiceMockTests
final class TorrentServiceMockTests: XCTestCase {
    func testInvalidMagnetThrows() async {
        let svc = TorrentService()
        do { _ = try await svc.add(magnet: "bad", selective: []); XCTFail("should throw") } catch { XCTAssertNotNil(error) }
    }
    func testValidMagnetAdds() async throws {
        let svc = TorrentService()
        let item = try await svc.add(magnet: "magnet:?xt=urn:btih:1234567890123456789012345678901234567890", selective: [])
        XCTAssertEqual(item.status, .downloading)
        XCTAssertTrue(item.savePathRelative.contains("Downloads"))
    }
    func testPauseResume() async throws {
        let svc = TorrentService()
        let item = try await svc.add(magnet: "magnet:?xt=urn:btih:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", selective: [])
        await svc.pause(id: item.id)
        await svc.resume(id: item.id)
    }
}

// MARK: - FileManagerServiceTests
final class FileManagerServiceTests: XCTestCase {
    func testContentsListsTmp() throws {
        let svc = FileManagerService()
        let tmp = FileManager.default.temporaryDirectory
        let items = try svc.contents(of: tmp)
        XCTAssertNotNil(items)
    }
    func testDeleteGuardsOutsideDocuments() throws {
        let svc = FileManagerService()
        let outside = URL(fileURLWithPath: "/tmp/shouldNotDelete")
        // should not throw but guard prevents delete
        try svc.delete([outside])
    }
}
