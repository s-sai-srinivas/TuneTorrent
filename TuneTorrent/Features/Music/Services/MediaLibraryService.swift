import Foundation
import MediaPlayer
import AVFoundation

// MARK: - MediaLibraryService
protocol MediaLibraryServiceProtocol {
    func fetchAllSongs() async -> [Song]
}

final class MediaLibraryService: MediaLibraryServiceProtocol {
    func fetchAllSongs() async -> [Song] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return [] }
        let query = MPMediaQuery.songs()
        guard let items = query.items else { return [] }
        return items.compactMap { item -> Song? in
            guard let url = item.assetURL else { return nil }
            let title = item.title ?? url.deletingPathExtension().lastPathComponent
            return Song(urlPath: url.absoluteString, title: title, artist: item.artist ?? "Unknown", album: item.albumTitle ?? "Unknown", duration: item.playbackDuration, fileSize: 0)
        }
    }
}

final class MockMediaLibraryService: MediaLibraryServiceProtocol {
    func fetchAllSongs() async -> [Song] { [] }
}
