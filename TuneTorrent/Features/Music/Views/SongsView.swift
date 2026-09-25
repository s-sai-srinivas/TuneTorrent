import SwiftUI

// MARK: - SongsView
struct SongsViewFull: View {
    @StateObject private var vm = MusicViewModel()
    @State private var showPlayer = false
    @State private var shareSongURLs: [URL] = []
    @State private var showShare = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $vm.selectedTab) {
                ForEach(MusicViewModel.MusicTab.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }.pickerStyle(.segmented).padding()

            if vm.selectedTab == .songs {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search title, artist, album", text: $vm.searchText).onChange(of: vm.searchText) { _, _ in vm.apply() }.accessibilityIdentifier("MusicSearchField")
                    Menu("Sort") {
                        Button("Name") { vm.sort = .name; vm.apply() }
                        Button("Date") { vm.sort = .date; vm.apply() }
                        Button("Size") { vm.sort = .size; vm.apply() }
                        Button("Duration") { vm.sort = .duration; vm.apply() }
                    }.accessibilityIdentifier("MusicSortMenu")
                }.padding(.horizontal)
            }

            switch vm.selectedTab {
            case .songs:
                if vm.isLoading {
                    ProgressView().padding()
                } else if vm.filtered.isEmpty {
                    EmptyStateView(icon: "music.note", title: "No songs found", subtitle: "Grant Music access or add files to Downloads in Files → Import.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            HStack(spacing:8){
                                LiquidGlassButton(title: vm.sort == .name ? "Name ✓" : "Name", systemImage:"arrow.up.arrow.down"){ vm.sort = .name; vm.apply() }
                                LiquidGlassButton(title:"Favorites", systemImage:"heart"){ vm.showFavoritesOnly.toggle(); vm.apply() }
                                Spacer()
                                Text("\(vm.filtered.count) songs").font(.caption2).foregroundStyle(.secondary)
                            }.padding(.horizontal, 16)
                            ForEach(vm.filtered, id: \.id) { song in
                                GlassCard {
                                    SongRow(song: song).onTapGesture { vm.play(song); showPlayer = true }
                                }.padding(.horizontal, 12).contextMenu {
                                    Button(song.isFavorite ? "Unfavorite" : "Favorite", systemImage: "heart") {
                                        song.isFavorite.toggle()
                                        vm.apply()
                                    }
                                    Button("Share", systemImage: "square.and.arrow.up") {
                                        if let u = song.url {
                                            shareSongURLs = [u]
                                            showShare = true
                                        }
                                    }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        if let u = song.url, u.path.contains("Documents") {
                                            try? FileManager.default.removeItem(at: u)
                                            Task { await vm.load() }
                                        }
                                    }
                                }
                            }
                        }.padding(.vertical, 8)
                    }
                }
            case .albums:
                AlbumsView(groups: vm.albums)
            case .artists:
                ArtistsView(groups: vm.artists)
            case .playlists:
                PlaylistsView()
            case .folders:
                FoldersView(groups: vm.folders)
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showPlayer) { FullPlayerView() }
        .sheet(isPresented: $showShare) {
            if !shareSongURLs.isEmpty {
                ActivityView(activityItems: shareSongURLs)
            }
        }
        .overlay(alignment: .bottom) { MiniPlayerView { showPlayer = true } }
    }
}

// MARK: - SongRow
struct SongRow: View {
    let song: Song
    var body: some View {
        HStack(spacing: 12) {
            if let data = song.artworkData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6).fill(.secondary.opacity(0.2)).frame(width: 48, height: 48).overlay { Image(systemName: "music.note").foregroundStyle(.secondary) }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).lineLimit(1).font(.subheadline.weight(.medium))
                Text("\(song.artist) • \(song.album) • \(Formatters.duration(song.duration))").font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(Formatters.bytes(song.fileSize)).font(.caption2).foregroundStyle(.secondary)
            Image(systemName: "ellipsis").foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
}
