import Foundation
import UniformTypeIdentifiers

// MARK: - FileItem
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date
    var utType: UTType { UTType(filenameExtension: url.pathExtension) ?? .data }
}

// MARK: - StorageBreakdown
struct StorageBreakdown {
    var music: Int64 = 0
    var video: Int64 = 0
    var torrents: Int64 = 0
    var documents: Int64 = 0
    var other: Int64 = 0
    var totalUsed: Int64 { music + video + torrents + documents + other }
    var free: Int64 = 0
}
