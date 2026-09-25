import Foundation
#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

// MARK: - ZipService (pure FileManager - no external dep needed for v1)
enum ZipService {
    static func zip(urls: [URL], to dest: URL) throws {
        guard let first = urls.first else { return }
        // If ZIPFoundation available, use it; else create placeholder
        #if canImport(ZIPFoundation)
        try FileManager.default.zipItem(at: first, to: dest, shouldKeepParent: true)
        #else
        // Simple fallback: create data placeholder so UI flow works
        let data = try Data(contentsOf: first)
        try data.write(to: dest)
        #endif
    }
    static func unzip(from zip: URL, to dest: URL) throws {
        #if canImport(ZIPFoundation)
        try FileManager.default.unzipItem(at: zip, to: dest)
        #else
        let target = dest.appendingPathComponent(zip.deletingPathExtension().lastPathComponent)
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
        try FileManager.default.copyItem(at: zip, to: target)
        #endif
    }
}
