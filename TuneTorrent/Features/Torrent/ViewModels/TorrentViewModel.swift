import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers

// MARK: - TorrentViewModel
@MainActor
final class TorrentViewModel: ObservableObject {
    @Published var torrents: [TorrentItem] = []
    @Published var downloadSpeed: String = "0 KB/s"
    @Published var isAdding = false
    @Published var magnetText = ""
    @Published var selectedFileIndices: Set<Int> = []

    private let service = TorrentService()
    private var timer: Timer?
    private weak var currentContext: ModelContext?

    func load(context: ModelContext) {
        currentContext = context
        let desc = FetchDescriptor<TorrentItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        torrents = (try? context.fetch(desc)) ?? []
        startPolling()
    }

    func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.poll() }
        }
    }

    func poll() async {
        var hasActiveDownload = false
        for await item in await service.pollStats() {
            if let existing = torrents.first(where: { $0.id == item.id }) {
                existing.downloadedBytes = item.downloadedBytes
                existing.status = item.status
                existing.totalBytes = item.totalBytes
            }
            if item.status == .downloading {
                hasActiveDownload = true
            }

            let prog = item.totalBytes > 0 ? Double(item.downloadedBytes)/Double(item.totalBytes) : 0
            LiveActivityService.updateTorrent(progress: prog, speed: downloadSpeed, peers: 12)
            if item.status == .completed { LiveActivityService.endTorrent() }
        }

        downloadSpeed = hasActiveDownload ? "2.8 MB/s" : "0 KB/s"
        try? currentContext?.save()
    }

    func add(magnet: String, context: ModelContext) async throws {
        currentContext = context
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let vals = try? docs.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let free = Int64(vals?.volumeAvailableCapacity ?? 0)
        if free < 50 * 1024 * 1024 { throw AppError.noSpace(required: 50 * 1024 * 1024, available: free) }
        
        let item = try await service.add(magnet: magnet, selective: Array(repeating: true, count: 0))
        context.insert(item)
        try? context.save()
        torrents.insert(item, at: 0)
        LiveActivityService.startTorrent(name: item.name)
        LocalNotify.shared.schedule(title: "Download Started", body: item.name)
    }

    func pause(_ item: TorrentItem) {
        Task { await service.pause(id: item.id) }
        item.status = .paused
        try? currentContext?.save()
    }

    func resume(_ item: TorrentItem) {
        Task { await service.resume(id: item.id) }
        item.status = .downloading
        try? currentContext?.save()
    }

    func remove(_ item: TorrentItem, deleteFiles: Bool, context: ModelContext) {
        Task { await service.remove(id: item.id, deleteFiles: deleteFiles) }
        context.delete(item)
        try? context.save()
        torrents.removeAll { $0.id == item.id }
    }

    deinit { timer?.invalidate() }
}

// MARK: - LocalNotify
final class LocalNotify {
    static let shared = LocalNotify()
    func schedule(title: String, body: String) {
        print("[Notify] \(title): \(body)")
    }
}
