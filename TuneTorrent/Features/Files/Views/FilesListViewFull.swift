import SwiftUI
import QuickLook
import UniformTypeIdentifiers

// MARK: - FilesListViewFull
struct FilesListViewFull: View {
    @StateObject private var vm = FilesViewModel()
    @State private var previewURL: URL?
    @State private var showNewFolder = false
    @State private var folderName = ""
    @State private var showConfirmDelete = false
    @State private var showImporter = false
    @State private var importError: String?
    @State private var itemToRename: FileItem?
    @State private var showRename = false
    @State private var renameText = ""
    @State private var showMoveSheet = false
    @State private var isCopying = false
    @State private var shareURLs: [URL] = []
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            StorageHeaderView(breakdown: vm.breakdown)
            // breadcrumbs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(vm.breadcrumbs.enumerated()), id: \.offset) { idx, url in
                        Button(url.lastPathComponent.isEmpty ? "Documents" : url.lastPathComponent) { vm.breadcrumbs = Array(vm.breadcrumbs.prefix(idx+1)); vm.currentURL = url; vm.load() }
                        if idx < vm.breadcrumbs.count - 1 { Image(systemName: "chevron.right").font(.caption2) }
                    }
                }.padding(.horizontal)
            }.padding(.vertical, 6)

            HStack {
                TextField("Search", text: $vm.searchText).textFieldStyle(.roundedBorder).onChange(of: vm.searchText) { _, _ in vm.apply() }
                Menu("Sort") {
                    Button("Name") { vm.sort = .name; vm.apply() }
                    Button("Date") { vm.sort = .date; vm.apply() }
                    Button("Size") { vm.sort = .size; vm.apply() }
                    Button("Type") { vm.sort = .type; vm.apply() }
                }
                Button(vm.isGrid ? "List" : "Grid") { vm.isGrid.toggle() }
                Button(vm.isSelecting ? "Done" : "Select") { vm.isSelecting.toggle() }
            }.padding(.horizontal, 8)

            HiddenToggleView(showHidden: $vm.showHidden)
            if vm.isGrid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                    ForEach(vm.items.filter{ vm.showHidden || !$0.name.hasPrefix(".") }) { item in FileGridCell(item: item, selected: vm.selection.contains(item.id), selecting: vm.isSelecting) { vm.selection.insert(item.id) } onTap: { handleTap(item) } }
                }.padding()
            } else {
                List(vm.items.filter{ vm.showHidden || !$0.name.hasPrefix(".") }) { item in
                    GlassCard{ FileRowFull(item: item, selected: vm.selection.contains(item.id), selecting: vm.isSelecting) { vm.selection.insert(item.id) } onTap: { handleTap(item) } }
                    .listRowSeparator(.hidden).listRowBackground(Color.clear)
                    .contextMenu {
                        Button("Zip", systemImage: "archivebox") { try? vm.zipSelected(to: item.name + ".zip") }
                        Button("Rename", systemImage: "pencil") {
                            itemToRename = item
                            renameText = item.name
                            showRename = true
                        }
                        Button("Share", systemImage: "square.and.arrow.up") {
                            shareURLs = [item.url]
                            showShareSheet = true
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) { try? vm.fmServiceDelete([item.url]) }
                    }
                }.listStyle(.plain).scrollContentBackground(.hidden)
            }
            DuplicatesView(items: vm.duplicates){ toDel in try? vm.fmServiceDelete(toDel.map{$0.url}); vm.load() }
                .padding(.horizontal).task{ await vm.findDuplicates() }
            Spacer()
            if vm.isSelecting && !vm.selection.isEmpty {
                GlassCard{
                    HStack(spacing:10) {
                        LiquidGlassButton(title:"Move", systemImage:"folder"){
                            isCopying = false
                            showMoveSheet = true
                        }
                        LiquidGlassButton(title:"Copy", systemImage:"doc.on.doc"){
                            isCopying = true
                            showMoveSheet = true
                        }
                        LiquidGlassButton(title:"Zip", systemImage:"archivebox"){ try? vm.zipSelected(to: "Archive.zip") }
                        Button("Share", systemImage:"square.and.arrow.up"){
                            shareURLs = vm.selectedItems.map { $0.url }
                            showShareSheet = true
                        }
                        Spacer()
                        Button("Delete (\(vm.selection.count))", role:.destructive){ showConfirmDelete = true }.font(.caption.weight(.semibold))
                    }
                }.padding(.horizontal, 8)
            }
            if vm.showUndo {
                GlassCard(tint: Theme.accent){
                    HStack{ Text("Deleted \(vm.lastDeleted.count) items").font(.caption.weight(.semibold)); Spacer(); Button("Undo"){ vm.undoDelete() }.font(.caption.weight(.bold)) }
                }.padding(.horizontal)
            }
        }
        .navigationTitle("Files")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button { showImporter = true } label: { Label("Import", systemImage: "square.and.arrow.down") }.accessibilityIdentifier("FilesImportButton")
                    Button { showNewFolder = true } label: { Image(systemName: "folder.badge.plus") }.accessibilityIdentifier("FilesNewFolderButton")
                }
            }
        }
        .task { vm.load() }
        .alert("New Folder", isPresented: $showNewFolder) { TextField("Name", text: $folderName); Button("Create") { vm.createFolder(name: folderName); folderName = "" }; Button("Cancel", role: .cancel) {} }
        .alert("Rename", isPresented: $showRename) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let item = itemToRename, !renameText.isEmpty {
                    try? vm.rename(item, to: renameText)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete \(vm.selection.count) files (\(Formatters.bytes(vm.totalSelectedSize)))?", isPresented: $showConfirmDelete, titleVisibility: .visible) { Button("Delete", role: .destructive) { try? vm.deleteSelected() } }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio, .movie, .pdf, .zip, .data, .folder], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let dest = vm.currentURL.appendingPathComponent(url.lastPathComponent)
                        if FileManager.default.fileExists(atPath: dest.path) { try FileManager.default.removeItem(at: dest) }
                        try FileManager.default.copyItem(at: url, to: dest)
                    } catch { importError = error.localizedDescription }
                }
                vm.load()
            case .failure(let e): importError = e.localizedDescription
            }
        }
        .alert("Import Failed", isPresented: .constant(importError != nil)) { Button("OK") { importError = nil } } message: { Text(importError ?? "") }
        .sheet(item: Binding(get: { previewURL.map{ IdentifiableURL(url: $0) } }, set: { previewURL = $0?.url })) { item in QuickLookPreview(url: item.url) }
        .sheet(isPresented: $showShareSheet) {
            if !shareURLs.isEmpty {
                ActivityView(activityItems: shareURLs)
            }
        }
        .sheet(isPresented: $showMoveSheet) {
            FolderPickerSheet(currentURL: vm.currentURL) { targetURL in
                if isCopying {
                    try? vm.copySelected(to: targetURL)
                } else {
                    try? vm.moveSelected(to: targetURL)
                }
            }
        }
    }

    private func handleTap(_ item: FileItem) {
        if item.isDirectory { vm.navigate(to: item.url) } else { previewURL = item.url }
    }
}

struct IdentifiableURL: Identifiable { let url: URL; var id: String { url.absoluteString } }
// URL helper
extension URL { var fileID: String { absoluteString } }

// MARK: - FileRowFull (with thumbnail)
struct FileRowFull: View {
    let item: FileItem
    var selected: Bool
    var selecting: Bool
    var onSelect: () -> Void
    var onTap: () -> Void
    @State private var thumb: UIImage?
    var body: some View {
        HStack(spacing: 10) {
            if selecting { Button(action: onSelect) { Image(systemName: selected ? "checkmark.circle.fill" : "circle") } }
            Group{
                if let t = thumb {
                    Image(uiImage: t).resizable().scaledToFill().frame(width:48,height:48).clipShape(RoundedRectangle(cornerRadius:8, style:.continuous)).overlay(RoundedRectangle(cornerRadius:8, style:.continuous).stroke(Theme.glassStroke, lineWidth:0.6))
                } else {
                    ZStack{
                        RoundedRectangle(cornerRadius:8, style:.continuous).fill(.ultraThinMaterial).frame(width:48,height:48).overlay(RoundedRectangle(cornerRadius:8, style:.continuous).stroke(Theme.glassStroke, lineWidth:0.6))
                        Image(systemName: item.isDirectory ? "folder.fill" : (item.utType.conforms(to: .audio) ? "music.note" : item.utType.conforms(to: .movie) ? "film" : item.utType.conforms(to: .image) ? "photo" : "doc")).foregroundStyle(item.isDirectory ? .blue : .secondary)
                    }.frame(width:48,height:48)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline).lineLimit(1)
                Text("\(Formatters.bytes(item.size)) • \(item.modifiedDate.formatted(date: .abbreviated, time: .omitted))").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if !selecting { Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary) }
        }.contentShape(Rectangle()).onTapGesture { selecting ? onSelect() : onTap() }
        .task{ thumb = await ThumbnailService.shared.thumbnail(for: item.url, size: CGSize(width:96,height:96)) }
    }
}

struct FileGridCell: View {
    let item: FileItem; var selected: Bool; var selecting: Bool; var onSelect: () -> Void; var onTap: () -> Void
    @State private var thumb: UIImage?
    var body: some View {
        VStack(spacing:6) {
            Group{
                if let t = thumb { Image(uiImage:t).resizable().scaledToFill().frame(width:84,height:84).clipShape(RoundedRectangle(cornerRadius:12, style:.continuous)) }
                else { ZStack{ RoundedRectangle(cornerRadius:12, style:.continuous).fill(.ultraThinMaterial).frame(width:84,height:84); Image(systemName: item.isDirectory ? "folder.fill" : item.utType.conforms(to: .image) ? "photo" : item.utType.conforms(to: .movie) ? "film" : "doc").font(.title2).foregroundStyle(.blue) }.frame(width:84,height:84) }
            }.overlay(RoundedRectangle(cornerRadius:12, style:.continuous).stroke(Theme.glassStroke, lineWidth:0.7))
            Text(item.name).font(.caption2).lineLimit(2).multilineTextAlignment(.center)
        }.padding(8).background(selected ? Theme.accent.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 12, style:.continuous)).onTapGesture { selecting ? onSelect() : onTap() }
        .task{ thumb = await ThumbnailService.shared.thumbnail(for: item.url, size: CGSize(width:168,height:168)) }
    }
}

// MARK: - StorageHeaderView
struct StorageHeaderView: View {
    let breakdown: StorageBreakdown
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Used \(Formatters.bytes(breakdown.totalUsed)) / Free \(Formatters.bytes(breakdown.free))").font(.caption.weight(.semibold))
                StorageBar(breakdown: breakdown)
                HStack(spacing: 8) {
                    Legend(color: .blue, label: "Music \(Formatters.bytes(breakdown.music))")
                    Legend(color: .purple, label: "Video \(Formatters.bytes(breakdown.video))")
                    Legend(color: .orange, label: "Torrents \(Formatters.bytes(breakdown.torrents))")
                }.font(.caption2)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Text("Large >100MB (0)").padding(6).background(.secondary.opacity(0.15), in: Capsule())
                        Text("Duplicates (0)").padding(6).background(.secondary.opacity(0.15), in: Capsule())
                        Text("Incomplete (0)").padding(6).background(.secondary.opacity(0.15), in: Capsule())
                    }.font(.caption2)
                }
            }
        }.padding(.horizontal)
    }
}

struct Legend: View { let color: Color; let label: String; var body: some View { HStack(spacing: 4) { Circle().fill(color).frame(width: 8, height: 8); Text(label) } } }

// MARK: - Helpers
extension FilesViewModel { func fmServiceDelete(_ urls: [URL]) throws { try fmService.delete(urls) } }
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> QLPreviewController {
        let c = QLPreviewController(); c.dataSource = context.coordinator; return c
    }
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(url: url) }
    class Coord: NSObject, QLPreviewControllerDataSource {
        let url: URL; init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { url as QLPreviewItem }
    }
}

// MARK: - ActivityView (Share Sheet)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - FolderPickerSheet (Move / Copy destination)
struct FolderPickerSheet: View {
    let currentURL: URL
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var folders: [FileItem] = []

    var body: some View {
        NavigationStack {
            List {
                Button(action: { onSelect(currentURL); dismiss() }) {
                    Label("Current Folder (\(currentURL.lastPathComponent.isEmpty ? "Documents" : currentURL.lastPathComponent))", systemImage: "folder")
                }
                if !folders.isEmpty {
                    Section("Subfolders") {
                        ForEach(folders) { f in
                            Button(action: { onSelect(f.url); dismiss() }) {
                                Label(f.name, systemImage: "folder.fill")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Destination")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                let fm = FileManagerService()
                let items = (try? fm.contents(of: currentURL)) ?? []
                folders = items.filter { $0.isDirectory }
            }
        }
    }
}
