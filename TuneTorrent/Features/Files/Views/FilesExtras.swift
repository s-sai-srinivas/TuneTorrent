import SwiftUI

// MARK: - DuplicatesView (glassy)
struct DuplicatesView: View {
    let items: [FileItem]
    var onDelete: ([FileItem]) -> Void = {_ in}
    var body: some View {
        GlassCard{
            VStack(alignment:.leading, spacing:8){
                HStack{ Image(systemName:"doc.on.doc"); Text("Duplicates").font(.subheadline.weight(.semibold)); Spacer(); Text("\(items.count)").font(.caption2).padding(4).background(Color.secondary.opacity(0.15), in:Capsule()) }
                if items.isEmpty { Text("No duplicates found (by name+size).").font(.caption).foregroundStyle(.secondary) }
                else {
                    ForEach(items){ f in HStack{ Text(f.name).font(.caption).lineLimit(1); Spacer(); Text(Formatters.bytes(f.size)).font(.caption2).foregroundStyle(.secondary) } }
                    LiquidGlassButton(title:"Delete Duplicates", systemImage:"trash"){ onDelete(items) }
                }
            }
        }
    }
}

// MARK: - HiddenToggle
struct HiddenToggleView: View {
    @Binding var showHidden: Bool
    var body: some View {
        Toggle(isOn:$showHidden){ Label("Show hidden files", systemImage:"eye") }.font(.caption).tint(Theme.accent).padding(.horizontal)
    }
}
