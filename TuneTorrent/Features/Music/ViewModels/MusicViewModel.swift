import Foundation
import SwiftData
import Combine

// MARK: - MusicViewModel
@MainActor
final class MusicViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var filtered: [Song] = []
    @Published var searchText = ""
    @Published var sort: Sort = .name
    @Published var selectedTab: MusicTab = .songs
    @Published var isLoading = false
    @Published var permissionGranted = false
    @Published var showFavoritesOnly = false

    enum Sort { case name, date, size, duration }
    enum MusicTab: String, CaseIterable { case songs, albums, artists, playlists, folders }

    private let mediaService: MediaLibraryServiceProtocol
    private let scanService: FileScanServiceProtocol
    private let playback: PlaybackService

    init(mediaService: MediaLibraryServiceProtocol = MediaLibraryService(), scanService: FileScanServiceProtocol = FileScanService(), playback: PlaybackService? = nil) {
        self.mediaService = mediaService
        self.scanService = scanService
        self.playback = playback ?? PlaybackService.shared
    }

    func load() async {
        isLoading = true
        async let a = mediaService.fetchAllSongs()
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        async let b = scanService.scanAudioFiles(in: docs)
        let (m, f) = await (a, b)
        var all = m + f
        // dedupe by urlPath
        var seen = Set<String>()
        all = all.filter { seen.insert($0.urlPath).inserted }
        songs = all
        apply()
        isLoading = false
    }

    func apply() {
        var r = songs
        if showFavoritesOnly { r = r.filter { $0.isFavorite } }
        if !searchText.isEmpty {
            r = r.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.artist.localizedCaseInsensitiveContains(searchText) || $0.album.localizedCaseInsensitiveContains(searchText) }
        }
        switch sort {
        case .name: r.sort { $0.title < $1.title }
        case .date: r.sort { $0.createdAt > $1.createdAt }
        case .size: r.sort { $0.fileSize > $1.fileSize }
        case .duration: r.sort { $0.duration > $1.duration }
        }
        filtered = r
    }

    var albums: [String: [Song]] { Dictionary(grouping: filtered, by: { $0.album }) }
    var artists: [String: [Song]] { Dictionary(grouping: filtered, by: { $0.artist }) }
    var folders: [String: [Song]] { Dictionary(grouping: filtered, by: { URL(fileURLWithPath: $0.urlPath).deletingLastPathComponent().lastPathComponent }) }

    func play(_ song: Song) { playback.play(song, queue: filtered) }
}
