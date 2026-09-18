import Foundation
import SwiftData

// MARK: - TorrentStatus
enum TorrentStatus: String, Codable {
    case fetchingMetadata, downloading, paused, seeding, completed, error
}

// MARK: - TorrentItem
@Model
final class TorrentItem {
    @Attribute(.unique) var id: UUID
    var magnet: String
    var name: String
    var totalBytes: Int64
    var downloadedBytes: Int64
    var statusRaw: String
    var savePathRelative: String // Documents/Downloads/{torrentName}
    var fileSelectionsData: Data? // encoded [Bool]
    var createdAt: Date
    var errorMessage: String?

    var status: TorrentStatus {
        get { TorrentStatus(rawValue: statusRaw) ?? .error }
        set { statusRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), magnet: String, name: String, totalBytes: Int64 = 0, downloadedBytes: Int64 = 0, status: TorrentStatus = .fetchingMetadata, savePathRelative: String, fileSelections: [Bool] = [], createdAt: Date = .now) {
        self.id = id
        self.magnet = magnet
        self.name = name
        self.totalBytes = totalBytes
        self.downloadedBytes = downloadedBytes
        self.statusRaw = status.rawValue
        self.savePathRelative = savePathRelative
        self.fileSelectionsData = try? JSONEncoder().encode(fileSelections)
        self.createdAt = createdAt
    }

    var saveURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(savePathRelative)
    }
}
