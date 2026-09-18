import SwiftUI
import SwiftData

@main
struct TuneTorrentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Song.self, Playlist.self, TorrentItem.self])
    }
}
