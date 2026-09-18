import ActivityKit
import SwiftUI

// MARK: - LiveActivityService (Dynamic Island)

// Torrent Live Activity
struct TorrentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var name: String
        var progress: Double // 0...1
        var speed: String // "2.1 MB/s"
        var peers: Int
    }
    var id: UUID
}

enum LiveActivityService {
    static func startTorrent(name: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = TorrentActivityAttributes(id: UUID())
        let state = TorrentActivityAttributes.ContentState(name: name, progress: 0, speed: "0 MB/s", peers: 0)
        try? Activity.request(attributes: attrs, content: .init(state: state, staleDate: nil))
    }
    static func updateTorrent(progress: Double, speed: String, peers: Int) {
        Task{
            for activity in Activity<TorrentActivityAttributes>.activities {
                await activity.update(.init(state: .init(name: activity.content.state.name, progress: progress, speed: speed, peers: peers), staleDate: nil))
            }
        }
    }
    static func endTorrent() {
        Task{ for a in Activity<TorrentActivityAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) } }
    }

    // Music Live Activity (optional)
    static func startMusic(title: String, artist: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Reuse same attributes with music title
        startTorrent(name: "\(title) — \(artist)")
    }
}

// MARK: - Live Activity Widget (needs separate extension + Info.plist NSSupportsLiveActivities)
// Add to TuneTorrentWidget extension: Live Activity views using ActivityConfiguration
