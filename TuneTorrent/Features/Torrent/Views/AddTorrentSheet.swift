import SwiftUI
import UniformTypeIdentifiers

// MARK: - AddTorrentSheet
struct AddTorrentSheet: View {
    @ObservedObject var vm: TorrentViewModel
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) var dismiss
    @State private var error: String?
    @State private var showPicker = false
    @State private var preflightFiles: [String] = []
    @State private var selections: [Bool] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Magnet Link") {
                    TextField("magnet:?xt=urn:btih:...", text: $vm.magnetText)
                    HStack {
                        Button("Paste") { if let s = UIPasteboard.general.string { vm.magnetText = s } }
                        Spacer()
                        Button("Import .torrent") { showPicker = true }
                    }
                }
                if !preflightFiles.isEmpty {
                    Section("Files (select to download)") {
                        ForEach(preflightFiles.indices, id: \.self) { i in
                            HStack {
                                Button { selections[i].toggle() } label: { Image(systemName: selections[i] ? "checkmark.square.fill" : "square") }
                                Text(preflightFiles[i]).font(.caption)
                            }
                        }
                        Text("Save to: Documents/Downloads/\(vm.magnetText.prefix(12))").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if let e = error { Section { Text(e).foregroundStyle(.red).font(.caption) } }
                Section {
                    Button("Start Download") {
                        Task {
                            do {
                                // space check done in vm
                                try await vm.add(magnet: vm.magnetText, context: ctx)
                                dismiss()
                            } catch { error = error.localizedDescription }
                        }
                    }.disabled(!vm.magnetText.hasPrefix("magnet:"))
                }
            }
            .navigationTitle("Add Torrent")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .fileImporter(isPresented: $showPicker, allowedContentTypes: [UTType.data]) { result in
                if case .success(let url) = result { vm.magnetText = url.absoluteString; preflightFiles = ["file1.mp3","file2.mp3"] ; selections = [true,true] }
            }
        }
    }
}
