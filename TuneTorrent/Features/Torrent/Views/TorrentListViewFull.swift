import SwiftUI
import SwiftData

// MARK: - TorrentListViewFull
struct TorrentListViewFull: View {
    @Query(sort: \TorrentItem.createdAt, order: .reverse) var torrents: [TorrentItem]
    @Environment(\.modelContext) private var ctx
    @StateObject private var vm = TorrentViewModel()
    @State private var showAdd = false
    @State private var showSettings = false

    var body: some View {
        List {
            if !torrents.isEmpty {
                Section("Active \(torrents.filter { $0.status == .downloading }.count) | Completed \(torrents.filter { $0.status == .completed }.count)") {
                    ForEach(torrents) { t in
                        NavigationLink(value: t) {
                            GlassCard{ TorrentRow(item: t, onPause: { vm.pause(t) }, onResume: { vm.resume(t) }) }
                        }.listRowSeparator(.hidden).listRowBackground(Color.clear)
                    }
                    Section{ RSSView() }.listRowBackground(Color.clear).listRowSeparator(.hidden)
                }
            }
        }
        .overlay { if torrents.isEmpty { EmptyStateView(icon: "arrow.down.circle", title: "No torrents", subtitle: "Tap + to add magnet or .torrent") } }
        .navigationTitle("Torrents")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing:12){
                    Button{ showSettings = true } label:{ Image(systemName:"slider.horizontal.3") }
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent) }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTorrentSheet(vm: vm) }
        .sheet(isPresented: $showSettings){ TorrentSettingsSheet() }
        .navigationDestination(for: TorrentItem.self) { TorrentDetailView(item: $0) }
        .task { vm.load(context: ctx) }
    }
}

// MARK: - TorrentRow
struct TorrentRow: View {
    let item: TorrentItem
    var onPause: () -> Void
    var onResume: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name).font(.subheadline.weight(.medium)).lineLimit(1)
                Spacer()
                StatusChip(status: item.status)
            }
            ProgressView(value: Double(item.downloadedBytes), total: Double(max(item.totalBytes, 1)))
                .tint(item.status == .completed ? .green : .blue)
            HStack(spacing: 8) {
                Text("\(Int(Double(item.downloadedBytes)/Double(max(item.totalBytes,1))*100))%")
                Text(Formatters.bytes(item.downloadedBytes) + " / " + Formatters.bytes(item.totalBytes))
                Spacer()
                if item.status == .downloading { Button("Pause", action: onPause) } else if item.status == .paused { Button("Resume", action: onResume) }
            }.font(.caption2).foregroundStyle(.secondary)
            Text("↓ 0 MB/s ↑ 0 MB/s • 0 peers").font(.caption2).foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
}

struct StatusChip: View {
    let status: TorrentStatus
    var color: Color {
        switch status { case .downloading: return .blue; case .paused: return .gray; case .completed: return .green; case .error: return .red; default: return .orange }
    }
    var body: some View { Text(status.rawValue).font(.caption2.weight(.bold)).padding(.horizontal, 6).padding(.vertical, 2).background(color.opacity(0.15), in: Capsule()).foregroundStyle(color) }
}
