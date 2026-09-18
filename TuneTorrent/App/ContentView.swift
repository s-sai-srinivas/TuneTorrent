import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MusicTabView()
                .tabItem { Label("Music", systemImage: "music.note") }.tag(0)
                .accessibilityIdentifier("MusicTab")
            TorrentTabView()
                .tabItem { Label("Torrent", systemImage: "arrow.down.circle") }.badge(TorrentBadge.count).tag(1)
                .accessibilityIdentifier("TorrentTab")
            FilesTabView()
                .tabItem { Label("Files", systemImage: "folder") }.tag(2)
                .accessibilityIdentifier("FilesTab")
        }
        .accessibilityIdentifier("MainTabView")
        .tint(Theme.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

// MARK: - Tab Stubs

struct MusicTabView: View {
    var body: some View { NavigationStack { SongsViewFull().navigationTitle("Music") } }
}

struct TorrentTabView: View {
    var body: some View { NavigationStack { TorrentListViewFull().navigationTitle("Torrents") } }
}

struct FilesTabView: View {
    var body: some View { NavigationStack { FilesListViewFull().navigationTitle("Files").toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink(destination: SettingsView()) { Image(systemName: "gearshape") } } } } }
}

enum TorrentBadge { static var count: Int { 0 } }

// MARK: - Preview
#Preview {
    ContentView()
}
