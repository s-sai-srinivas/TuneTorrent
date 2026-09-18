import Foundation
import UniformTypeIdentifiers

// MARK: - StorageAnalyzerService
actor StorageAnalyzerService {
    func breakdown(root: URL) async -> StorageBreakdown {
        var b = StorageBreakdown()
        if let vals = try? root.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]) {
            b.free = Int64(vals.volumeAvailableCapacity ?? 0)
        }
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return b }
        for case let url as URL in en {
            let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            let ext = url.pathExtension.lowercased()
            if ["mp3","m4a","wav","flac","aac","aiff","opus"].contains(ext) { b.music += size }
            else if ["mp4","mov","mkv","avi"].contains(ext) { b.video += size }
            else if url.path.contains("Downloads") { b.torrents += size }
            else if ["pdf","doc","docx","txt"].contains(ext) { b.documents += size }
            else { b.other += size }
        }
        return b
    }

    // Cleanable helpers
    func largeFiles(in root: URL, threshold: Int64 = 100*1024*1024) async -> [FileItem] {
        var out: [FileItem] = []
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else { return [] }
        for case let url as URL in en {
            let vals = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if vals?.isDirectory == false, let s = vals?.fileSize, Int64(s) > threshold {
                out.append(FileItem(url: url, name: url.lastPathComponent, isDirectory: false, size: Int64(s), modifiedDate: Date()))
            }
        }
        return out.sorted { $0.size > $1.size }
    }
}
