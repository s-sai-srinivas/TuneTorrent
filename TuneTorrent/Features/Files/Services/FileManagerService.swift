import Foundation
import UniformTypeIdentifiers

// MARK: - FileManagerService
protocol FileManagerServiceProtocol {
    func contents(of url: URL) throws -> [FileItem]
    func size(of url: URL) async -> Int64
    func delete(_ urls: [URL]) throws
    func move(_ urls: [URL], to dest: URL) throws
    func copy(_ urls: [URL], to dest: URL) throws
}

final class FileManagerService: FileManagerServiceProtocol {
    func contents(of url: URL) throws -> [FileItem] {
        let fm = FileManager.default
        let urls = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey, .isSymbolicLinkKey], options: [.skipsHiddenFiles])
        return urls.compactMap { u in
            guard let vals = try? u.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]) else { return nil }
            return FileItem(url: u, name: u.lastPathComponent, isDirectory: vals.isDirectory ?? false, size: Int64(vals.fileSize ?? 0), modifiedDate: vals.contentModificationDate ?? Date())
        }
    }

    func size(of url: URL) async -> Int64 {
        await Task.detached(priority: .utility) {
            guard let vals = try? url.resourceValues(forKeys: [.isDirectoryKey]), vals.isDirectory == true else {
                return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            }
            var total: Int64 = 0
            if let en = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
                for case let f as URL in en { total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) }
            }
            return total
        }.value
    }

    func delete(_ urls: [URL]) throws {
        for u in urls {
            guard u.path.contains("Documents") else { continue }
            if #available(iOS 18, *) { try? FileManager.default.trashItem(at: u, resultingItemURL: nil) } else { try FileManager.default.removeItem(at: u) }
        }
    }

    func move(_ urls: [URL], to dest: URL) throws {
        for u in urls { let d = dest.appendingPathComponent(u.lastPathComponent); try FileManager.default.moveItem(at: u, to: d) }
    }

    func copy(_ urls: [URL], to dest: URL) throws {
        for u in urls { let d = dest.appendingPathComponent(u.lastPathComponent); try FileManager.default.copyItem(at: u, to: d) }
    }
}
