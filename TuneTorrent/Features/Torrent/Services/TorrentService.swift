import Foundation

// MARK: - TorrentService
actor TorrentService {
    // libtorrent session would be here: private var session: TorrentSession
    private var items: [UUID: TorrentItem] = [:]

    // Unrestricted: downloadLimit 0 = unlimited, max connections, DHT/PEX on, 6 concurrent
    private let maxConnections = 200
    func add(magnet: String, selective: [Bool]) async throws -> TorrentItem {
        guard magnet.range(of: #"magnet:\?xt=urn:btih:[a-zA-Z0-9]{32,40}"#, options: .regularExpression) != nil else {
            throw AppError.torrentFailed("Invalid magnet link")
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cap = try? docs.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        if let free = cap?.volumeAvailableCapacity, free < 50_000_000 { throw AppError.noSpace(required: 50_000_000, available: Int64(free)) }
        let name = "Torrent-\(magnet.suffix(8))"
        let rel = "Downloads/\(name)"
        let url = docs.appendingPathComponent(rel)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let item = TorrentItem(magnet: magnet, name: String(name), totalBytes: 700_000_000, downloadedBytes: 0, status: .downloading, savePathRelative: rel, fileSelections: selective)
        items[item.id] = item
        // Real libtorrent: session.applySettings(downloadRateLimit: 0, uploadRateLimit: 0, connectionsLimit: 200, dht: true, pex: true, sequential: false, activeDownloads: 6)
        return item
    }

    func pause(id: UUID) { items[id]?.status = .paused }
    func resume(id: UUID) { items[id]?.status = .downloading }
    func remove(id: UUID, deleteFiles: Bool) {
        if deleteFiles, let p = items[id]?.saveURL { try? FileManager.default.removeItem(at: p) }
        items.removeValue(forKey: id)
    }

    func pollStats() -> AsyncStream<TorrentItem> {
        AsyncStream { cont in
            for item in self.items.values {
                // simulate progress
                var c = item
                if c.status == .downloading { c.downloadedBytes = min(c.totalBytes, c.downloadedBytes + 5_000_000) ; if c.downloadedBytes >= c.totalBytes { c.status = .completed } }
                cont.yield(c)
            }
            cont.finish()
        }
    }

    // saveResumeData for background kill recovery
    func saveResumeData() async -> Data? { nil }
}
