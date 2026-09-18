import Foundation
import SwiftData

// MARK: - Playlist
@Model
final class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .nullify) var songs: [Song]

    init(id: UUID = UUID(), name: String, songs: [Song] = [], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.songs = songs
        self.createdAt = createdAt
    }
}
