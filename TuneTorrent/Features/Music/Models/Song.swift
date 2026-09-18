import Foundation
import SwiftData

// MARK: - Song
@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var urlPath: String
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var fileSize: Int64
    var artworkData: Data?
    var createdAt: Date
    var isFavorite: Bool = false
    var lyrics: String? // synced/unsynced
    var playCount: Int = 0
    var lastPlayed: Date?

    init(id: UUID = UUID(), urlPath: String, title: String, artist: String = "Unknown", album: String = "Unknown", duration: Double = 0, fileSize: Int64 = 0, artworkData: Data? = nil, createdAt: Date = .now, isFavorite: Bool = false, lyrics: String? = nil) {
        self.id = id; self.urlPath = urlPath; self.title = title; self.artist = artist; self.album = album; self.duration = duration; self.fileSize = fileSize; self.artworkData = artworkData; self.createdAt = createdAt; self.isFavorite = isFavorite; self.lyrics = lyrics
    }
    var url: URL? { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(urlPath) }
}
