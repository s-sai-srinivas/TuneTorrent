import Foundation
import AVFoundation

// MARK: - LyricsService
actor LyricsService {
    func loadLyrics(for url: URL) async -> String? {
        let asset = AVURLAsset(url: url)
        if let meta = try? await asset.load(.commonMetadata) {
            for item in meta where item.commonKey?.rawValue == "lyrics" {
                if let s = try? await item.load(.stringValue), !s.isEmpty { return s }
            }
        }
        // also try .lrc sidecar
        let lrc = url.deletingPathExtension().appendingPathExtension("lrc")
        if let s = try? String(contentsOf: lrc, encoding: .utf8) { return s }
        return nil
    }
}
