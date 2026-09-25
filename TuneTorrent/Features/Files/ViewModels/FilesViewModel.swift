import Foundation
import SwiftUI
import Combine

// MARK: - FilesViewModel
@MainActor
final class FilesViewModel: ObservableObject {
    @Published var currentURL: URL
    @Published var items: [FileItem] = []
    @Published var breadcrumbs: [URL] = []
    @Published var selection = Set<UUID>()
    @Published var isGrid = false
    @Published var sort: Sort = .name
    @Published var searchText = ""
    @Published var breakdown = StorageBreakdown()
    @Published var isSelecting = false
    @Published var showHidden = false
    @Published var duplicates: [FileItem] = []
    @Published var showUndo = false
    @Published var lastDeleted: [URL] = []

    enum Sort { case name, date, size, type }

    let fmService: FileManagerServiceProtocol
    private let analyzer = StorageAnalyzerService()

    init(fmService: FileManagerServiceProtocol = FileManagerService()) {
        self.fmService = fmService
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        self.currentURL = docs
        self.breadcrumbs = [docs]
    }

    func load() {
        do { items = try fmService.contents(of: currentURL) } catch { items = [] }
        apply()
        Task {
            if let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                breakdown = await analyzer.breakdown(root: root)
            }
        }
    }

    func apply() {
        var r = items
        if !searchText.isEmpty { r = r.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        switch sort {
        case .name: r.sort { $0.name < $1.name }
        case .date: r.sort { $0.modifiedDate > $1.modifiedDate }
        case .size: r.sort { $0.size > $1.size }
        case .type: r.sort { $0.utType.identifier < $1.utType.identifier }
        }
        items = r
    }

    func navigate(to url: URL) {
        guard (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { return }
        currentURL = url
        breadcrumbs.append(url)
        load()
    }

    func goBack() {
        guard breadcrumbs.count > 1 else { return }
        breadcrumbs.removeLast()
        if let last = breadcrumbs.last {
            currentURL = last
            load()
        }
    }

    var selectedItems: [FileItem] { items.filter { selection.contains($0.id) } }
    var totalSelectedSize: Int64 { selectedItems.reduce(0) { $0 + $1.size } }

    func deleteSelected() throws {
        let urls = selectedItems.map { $0.url }
        lastDeleted = urls
        try fmService.delete(urls); selection.removeAll(); showUndo = true; load()
        Task { try? await Task.sleep(nanoseconds: 4_000_000_000); await MainActor.run { showUndo = false } }
    }
    func undoDelete() { /* iOS 18 trash undo would move back; placeholder */ showUndo = false }
    func findDuplicates() async {
        var map: [String: [FileItem]] = [:]
        for i in items where !i.isDirectory { map["\(i.name)-\(i.size)", default:[]].append(i) }
        duplicates = map.values.filter{ $0.count>1 }.flatMap{ $0 }
    }
    func zipSelected(to name: String) throws {
        let urls = selectedItems.map{ $0.url }
        let dest = currentURL.appendingPathComponent(name.hasSuffix(".zip") ? name : name+".zip")
        try ZipService.zip(urls: urls, to: dest); load()
    }
    func createFolder(name: String) { let u = currentURL.appendingPathComponent(name); try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true); load() }

    func rename(_ item: FileItem, to newName: String) throws {
        _ = try fmService.rename(item.url, to: newName)
        load()
    }

    func moveSelected(to dest: URL) throws {
        let urls = selectedItems.map { $0.url }
        try fmService.move(urls, to: dest)
        selection.removeAll()
        load()
    }

    func copySelected(to dest: URL) throws {
        let urls = selectedItems.map { $0.url }
        try fmService.copy(urls, to: dest)
        selection.removeAll()
        load()
    }
}
