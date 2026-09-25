import SwiftUI

// MARK: - TorrentSettingsSheet (Unrestricted fast by default)
struct TorrentSettingsSheet: View {
    @AppStorage("dlLimit") private var dlLimit: Double = 0 // 0 = unlimited = FASTEST
    @AppStorage("ulLimit") private var ulLimit: Double = 0
    @AppStorage("dht") private var dht = true
    @AppStorage("pex") private var pex = true
    @State private var sequential = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Speed — Unrestricted Fast")) {
                    VStack(alignment:.leading, spacing:8){
                        HStack{ Image(systemName:"bolt.fill").foregroundStyle(.yellow); Text("Download: UNLIMITED (fastest)").font(.subheadline.weight(.semibold)); Spacer(); Text("UNLIMITED").font(.caption.weight(.bold)).foregroundStyle(.green).padding(4).background(Color.green.opacity(0.15), in:Capsule()) }
                        Text("Your torrents use full WiFi/data speed. No throttling.").font(.caption2).foregroundStyle(.secondary)
                        Toggle("Enable download cap (slow down if needed)", isOn: Binding(get:{dlLimit>0}, set:{ dlLimit = $0 ? 1000 : 0 }))
                        if dlLimit>0 {
                            HStack{ Text("Limit"); Spacer(); Text("\(Int(dlLimit)) KB/s").font(.caption).foregroundStyle(.secondary) }
                            Slider(value:$dlLimit, in:100...5000, step:100).tint(Theme.accent)
                        }
                        Divider()
                        HStack{ Text("Upload"); Spacer(); Text(ulLimit==0 ? "Unlimited" : "\(Int(ulLimit)) KB/s").font(.caption).foregroundStyle(.secondary) }
                        Slider(value:$ulLimit, in:0...2000, step:50).tint(Theme.accent)
                    }
                }
                Section(header: Text("Network — Max Speed")) {
                    Toggle("DHT (find more peers) — ON for speed", isOn:$dht)
                    Toggle("PEX (Peer Exchange) — ON for speed", isOn:$pex)
                    Toggle("Sequential download (stream while downloading)", isOn:$sequential)
                }
                Section(footer: Text("Defaults are UNLIMITED + DHT/PEX ON = fastest. Caps only if you toggle them. Settings saved via AppStorage and passed to libtorrent session.").font(.caption2)) { }
            }.navigationTitle("Torrent Speed").toolbar{ ToolbarItem(placement:.confirmationAction){ Button("Done"){dismiss()} } }
        }
    }
}

// MARK: - RSSView
struct RSSView: View {
    @State private var url = ""
    @State private var items: [String] = ["Top 100 Music Torrents (auto)","New FLAC releases"]
    var body: some View {
        GlassCard{
            VStack(alignment:.leading, spacing:10){
                HStack{ Image(systemName:"dot.radiowaves.left.and.right"); Text("RSS Auto-Download").font(.subheadline.weight(.semibold)); Spacer(); Image(systemName:"plus.circle") }
                HStack{ TextField("https:// rss url", text:$url).textFieldStyle(.roundedBorder); LiquidGlassButton(title:"Add", systemImage:"plus"){ if !url.isEmpty { items.append(url); url="" } } }
                ForEach(items, id:\.self){ i in HStack{ Text(i).font(.caption); Spacer(); Text("Auto").font(.caption2).padding(4).background(Theme.accent.opacity(0.15), in:Capsule()) } }
                Text("RSS is polled in background fetch; new magnet → auto-added.").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
