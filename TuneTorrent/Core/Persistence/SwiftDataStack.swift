import SwiftData
import Foundation

// MARK: - SwiftDataStack
enum SwiftDataStack {
    static let sharedContainer: ModelContainer = {
        let schema = Schema([Song.self, Playlist.self, TorrentItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }()
}
