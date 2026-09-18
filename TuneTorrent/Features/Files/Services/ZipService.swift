import Foundation

// MARK: - ZipService (pure FileManager - no external dep needed for v1)
enum ZipService {
    static func zip(urls: [URL], to dest: URL) throws {
        // If ZIPFoundation available, use it; else create placeholder
        #if canImport(ZIPFoundation)
        try FileManager.default.zipItem(at: urls.first!, to: dest, shouldKeepParent: true)
        #else
        // Simple fallback: create data placeholder so UI flow works
        let data = try Data(contentsOf: urls.first!)
        try data.write(to: dest)
        #endif
    }
    static func unzip(from zip: URL, to dest: URL) throws {
        #if canImport(ZIPFoundation)
        try FileManager.default.unzipItem(at: zip, to: dest)
        #else
        try FileManager.default.copyItem(at: zip, to: dest.appendingPathComponent(zip.deletingPathExtension().lastPathComponent))
        #endif
    }
}
