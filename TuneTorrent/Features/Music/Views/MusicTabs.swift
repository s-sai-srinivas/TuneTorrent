import SwiftUI
import SwiftData

// MARK: - AlbumsView
struct AlbumsView: View {
    let groups: [String: [Song]]
    @State private var expandedAlbums: Set<String> = []

    var body: some View {
        List {
            ForEach(groups.keys.sorted(), id: \.self) { name in
                Section {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedAlbums.contains(name) },
                            set: { isExp in
                                if isExp { expandedAlbums.insert(name) } else { expandedAlbums.remove(name) }
                            }
                        )
                    ) {
                        ForEach(groups[name] ?? [], id: \.id) { song in
                            SongRow(song: song)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    PlaybackService.shared.play(song, queue: groups[name] ?? [])
                                }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "opticaldisc")
                                .foregroundStyle(Theme.accent)
                            Text(name)
                                .font(.headline)
                            Spacer()
                            Text("\(groups[name]?.count ?? 0) tracks")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if groups.isEmpty {
                EmptyStateView(icon: "rectangle.stack", title: "No albums", subtitle: "Import audio in Files to see albums.")
            }
        }
    }
}

// MARK: - ArtistsView
struct ArtistsView: View {
    let groups: [String: [Song]]
    @State private var expandedArtists: Set<String> = []

    var body: some View {
        List {
            ForEach(groups.keys.sorted(), id: \.self) { name in
                Section {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedArtists.contains(name) },
                            set: { isExp in
                                if isExp { expandedArtists.insert(name) } else { expandedArtists.remove(name) }
                            }
                        )
                    ) {
                        ForEach(groups[name] ?? [], id: \.id) { song in
                            SongRow(song: song)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    PlaybackService.shared.play(song, queue: groups[name] ?? [])
                                }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(Theme.accent)
                            Text(name)
                                .font(.headline)
                            Spacer()
                            Text("\(groups[name]?.count ?? 0) tracks")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if groups.isEmpty {
                EmptyStateView(icon: "person", title: "No artists", subtitle: "Audio metadata will group artists here.")
            }
        }
    }
}

// MARK: - PlaylistsView
struct PlaylistsView: View {
    @Query var playlists: [Playlist]
    @Environment(\.modelContext) private var ctx
    @State private var name = ""

    var body: some View {
        List {
            Section("My Playlists") {
                ForEach(playlists) { pl in
                    HStack {
                        Image(systemName: "music.note.list")
                            .foregroundStyle(Theme.accent)
                        Text(pl.name)
                            .font(.headline)
                        Spacer()
                        Text("\(pl.songs.count) songs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { idx in
                    for i in idx { ctx.delete(playlists[i]) }
                }
            }

            Section("New Playlist") {
                HStack {
                    TextField("Playlist name", text: $name)
                    Button("Create") {
                        let p = Playlist(name: name)
                        ctx.insert(p)
                        name = ""
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if playlists.isEmpty && name.isEmpty {
                VStack(spacing: 12) {
                    EmptyStateView(icon: "music.note.list", title: "No playlists", subtitle: "Create custom playlists to organize your tracks.")
                }
            }
        }
    }
}

// MARK: - FoldersView
struct FoldersView: View {
    let groups: [String: [Song]]

    var body: some View {
        List {
            ForEach(groups.keys.sorted(), id: \.self) { folder in
                Section(header: Label(folder.isEmpty ? "Documents" : folder, systemImage: "folder.fill")) {
                    ForEach(groups[folder] ?? [], id: \.id) { song in
                        SongRow(song: song)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                PlaybackService.shared.play(song, queue: groups[folder] ?? [])
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if groups.isEmpty {
                EmptyStateView(icon: "folder", title: "No audio folders", subtitle: "Files organized into subfolders will appear here.")
            }
        }
    }
}
