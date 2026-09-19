import SwiftUI
import SwiftData

// MARK: - AlbumsView
struct AlbumsView: View {
    let groups: [String: [Song]]
    var body: some View {
        List(groups.keys.sorted(), id: \.self) { name in
            NavigationLink("\(name) (\(groups[name]?.count ?? 0))", value: name)
        }
        .overlay { if groups.isEmpty { EmptyStateView(icon: "rectangle.stack", title: "No albums", subtitle: "") } }
    }
}

// MARK: - ArtistsView
struct ArtistsView: View {
    let groups: [String: [Song]]
    var body: some View {
        List(groups.keys.sorted(), id: \.self) { name in Text(name) }
            .overlay { if groups.isEmpty { EmptyStateView(icon: "person", title: "No artists", subtitle: "") } }
    }
}

// MARK: - PlaylistsView
struct PlaylistsView: View {
    @Query var playlists: [Playlist]
    @Environment(\.modelContext) private var ctx
    @State private var name = ""
    var body: some View {
        List {
            ForEach(playlists) { pl in
                NavigationLink("\(pl.name) (\(pl.songs.count))", value: pl)
            }.onDelete { idx in for i in idx { ctx.delete(playlists[i]) } }
            HStack {
                TextField("New playlist", text: $name)
                Button("Add") { let p = Playlist(name: name); ctx.insert(p); name = "" }.disabled(name.isEmpty)
            }
        }
    }
}

// MARK: - FoldersView
struct FoldersView: View {
    let groups: [String: [Song]]
    var body: some View {
        List(groups.keys.sorted(), id: \.self) { folder in
            Section(folder) { ForEach(groups[folder] ?? [], id: \.id) { SongRow(song: $0) } }
        }
    }
}
