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

    func load(context: ModelContext) {
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
        for await item in await service.pollStats() {
            if let idx = torrents.firstIndex(where: { $0.id == item.id }) { torrents[idx] = item }
            // update Live Activity
            let prog = item.totalBytes > 0 ? Double(item.downloadedBytes)/Double(item.totalBytes) : 0
            LiveActivityService.updateTorrent(progress: prog, speed: "—", peers: 12)
            if item.status == .completed { LiveActivityService.endTorrent() }
        }
    }

    func add(magnet: String, context: ModelContext) async throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let vals = try? docs.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let free = Int64(vals?.volumeAvailableCapacity ?? 0)
        if free < 100 * 1024 * 1024 { throw AppError.noSpace(required: 100 * 1024 * 1024, available: free) }
        let item = try await service.add(magnet: magnet, selective: Array(repeating: true, count: 0))
        context.insert(item)
        torrents.insert(item, at: 0)
        LiveActivityService.startTorrent(name: item.name)
        LocalNotify.shared.schedule(title: "Torrent Added", body: item.name)
    }

    func pause(_ item: TorrentItem) { Task { await service.pause(id: item.id) }; item.status = .paused }
    func resume(_ item: TorrentItem) { Task { await service.resume(id: item.id) }; item.status = .downloading }
    func remove(_ item: TorrentItem, deleteFiles: Bool, context: ModelContext) {
        Task { await service.remove(id: item.id, deleteFiles: deleteFiles) }
        context.delete(item)
        torrents.removeAll { $0.id == item.id }
    }

    deinit { timer?.invalidate() }
}

// MARK: - LocalNotify
final class LocalNotify {
    static let shared = LocalNotify()
    func schedule(title: String, body: String) {
        // TODO: UNUserNotificationCenter
        print("[Notify] \(title): \(body)")
    }
}
