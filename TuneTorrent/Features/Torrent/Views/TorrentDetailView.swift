import SwiftUI

// MARK: - TorrentDetailView
struct TorrentDetailView: View {
    let item: TorrentItem
    @Environment(\.modelContext) private var ctx
    @StateObject private var vm = TorrentViewModel()
    var body: some View {
        ScrollView{ VStack(spacing:12){
            GlassCard{
                VStack(alignment:.leading, spacing:8){
                    Text(item.name).font(.headline)
                    TorrentRow(item: item, onPause:{}, onResume:{})
                }
            }.padding(.horizontal)
            }
        }
        List {
            Section{ Toggle("Sequential download", isOn: .constant(false)) }
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
                if item.status == .downloading { Button("Pause") { vm.pause(item) } }
                if item.status == .paused { Button("Resume") { vm.resume(item) } }
                Button("Open File", action: {})
                Button("Delete", role: .destructive) { vm.remove(item, deleteFiles: true, context: ctx) }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
