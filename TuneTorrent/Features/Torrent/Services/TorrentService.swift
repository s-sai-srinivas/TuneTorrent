import Foundation

// MARK: - TorrentService
actor TorrentService {
    // libtorrent session would be here: private var session: TorrentSession
    private var items: [UUID: TorrentItem] = [:]

    // Unrestricted: downloadLimit 0 = unlimited, max connections, DHT/PEX on, 6 concurrent
    private let maxConnections = 200
    func add(magnet: String, selective: [Bool]) async throws -> TorrentItem {
        guard let info = TorrentParser.parseMagnet(magnet) else {
            throw AppError.torrentFailed("Invalid magnet link")
        }
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AppError.fileNotFound(URL(fileURLWithPath: "Documents"))
        }
        let cap = try? docs.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        if let free = cap?.volumeAvailableCapacity, free < 50_000_000 {
            throw AppError.noSpace(required: 50_000_000, available: Int64(free))
        }
        let sanitizedName = info.name.replacingOccurrences(of: "/", with: "-")
        let rel = "Downloads/\(sanitizedName)"
        let url = docs.appendingPathComponent(rel)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let total = info.exactSize ?? 700_000_000
        let item = TorrentItem(
            magnet: magnet,
            name: sanitizedName,
            totalBytes: total,
            downloadedBytes: 0,
            status: .downloading,
            savePathRelative: rel,
            fileSelections: selective
        )
        items[item.id] = item
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
