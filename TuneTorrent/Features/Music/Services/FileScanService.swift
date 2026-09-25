import Foundation
import UniformTypeIdentifiers
import AVFoundation

// MARK: - FileScanService
protocol FileScanServiceProtocol {
    func scanAudioFiles(in root: URL) async -> [Song]
}

actor FileScanService: FileScanServiceProtocol {
    private let exts = ["mp3","m4a","wav","flac","aac","aiff","opus"]
    func scanAudioFiles(in root: URL) async -> [Song] {
        await Task.detached(priority: .utility) { [exts] in
            guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey], options: [.skipsHiddenFiles]) else { return [Song]() }
            var out: [Song] = []
            let rootStandard = root.resolvingSymlinksInPath().standardizedFileURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            
            for case let url as URL in enumerator {
                guard exts.contains(url.pathExtension.lowercased()) else { continue }
                let vals = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                let size = Int64(vals?.fileSize ?? 0)
                let asset = AVURLAsset(url: url)
                let duration = try? await asset.load(.duration)
                let secs = duration?.seconds ?? 0
                let title = url.deletingPathExtension().lastPathComponent
                
                // Robust relative path calculation
                let fileStandard = url.resolvingSymlinksInPath().standardizedFileURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                var rel = url.lastPathComponent
                if fileStandard.hasPrefix(rootStandard) {
                    let sub = String(fileStandard.dropFirst(rootStandard.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    if !sub.isEmpty { rel = sub }
                }
                
                var artist = "Unknown", album = "Downloads", artwork: Data? = nil
                if let meta = try? await asset.load(.commonMetadata) {
                    for item in meta {
                        if item.commonKey?.rawValue == "artist", let v = try? await item.load(.stringValue) { artist = v ?? artist }
                        if item.commonKey?.rawValue == "albumName", let v = try? await item.load(.stringValue) { album = v ?? album }
                        if item.commonKey?.rawValue == "artwork", let d = try? await item.load(.dataValue) { artwork = d }
                    }
                }
                out.append(Song(urlPath: rel, title: title, artist: artist, album: album, duration: secs, fileSize: size, artworkData: artwork, createdAt: vals?.creationDate ?? Date()))
                if out.count > 2000 { break }
            }
            return out
        }.value
    }
}
