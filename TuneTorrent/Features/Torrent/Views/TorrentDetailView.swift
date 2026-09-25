import SwiftUI

// MARK: - TorrentDetailView
struct TorrentDetailView: View {
    let item: TorrentItem
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TorrentViewModel()
    @State private var isSequential = false
    @State private var previewURL: URL?
    @State private var shareURLs: [URL] = []
    @State private var showShare = false

    var body: some View {
        List {
            Section {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name).font(.headline)
                        TorrentRow(item: item, onPause: { vm.pause(item) }, onResume: { vm.resume(item) })
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                Toggle("Sequential download", isOn: $isSequential)
            }

            Section("Info") {
                LabeledContent("Name", value: item.name)
                LabeledContent("Status", value: item.status.rawValue)
                LabeledContent("Size", value: Formatters.bytes(item.totalBytes))
                LabeledContent("Downloaded", value: Formatters.bytes(item.downloadedBytes))
                LabeledContent("Save to", value: item.savePathRelative)
                LabeledContent("Peers", value: "12 peers • 3 seeds")
                LabeledContent("ETA", value: "—")
            }

            Section("Controls") {
                if item.status == .downloading {
                    Button("Pause") { vm.pause(item) }
                }
                if item.status == .paused {
                    Button("Resume") { vm.resume(item) }
                }
                if let saveURL = item.saveURL, FileManager.default.fileExists(atPath: saveURL.path) {
                    Button("Open File / Folder") {
                        previewURL = saveURL
                    }
                    Button("Share") {
                        shareURLs = [saveURL]
                        showShare = true
                    }
                }
                Button("Delete", role: .destructive) {
                    vm.remove(item, deleteFiles: true, context: ctx)
                    dismiss()
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(get: { previewURL.map { IdentifiableURL(url: $0) } }, set: { previewURL = $0?.url })) { p in
            QuickLookPreview(url: p.url)
        }
        .sheet(isPresented: $showShare) {
            if !shareURLs.isEmpty {
                ActivityView(activityItems: shareURLs)
            }
        }
    }
}
