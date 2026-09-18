import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    var body: some View {
        List {
            Section("Storage") {
                Button("Clear Cache") { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory) }
                Button("Reset Torrents") {}
            }
            Section("About") { LabeledContent("Version", value: "1.0"); LabeledContent("Build", value: "Hybrid Option 2"); Link("GitHub", destination: URL(string: "https://github.com")!) }
            Section { Text("Music + Torrent + Files • iOS 17.4+ • Sideload via iloader").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("Settings")
    }
}
