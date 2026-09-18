import WidgetKit
import SwiftUI

// MARK: - TuneTorrent Widget (Now Playing + Storage)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now, title: "Blinding Lights", free: "48 GB free") }
    func getSnapshot(in context: Context, completion: @escaping (Entry)->Void){ completion(Entry(date:.now, title:"Blinding Lights", free:"48 GB free")) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>)->Void){
        let e = Entry(date:.now, title: UserDefaults(suiteName:"group.com.708cn.tunetorrent")?.string(forKey:"nowPlaying") ?? "Not Playing", free:"48 GB free")
        completion(Timeline(entries:[e], policy:.atEnd))
    }
}
struct Entry: TimelineEntry { let date: Date; let title: String; let free: String }
struct WidgetEntryView: View {
    var entry: Entry
    var body: some View {
        GlassCard{
            VStack(alignment:.leading, spacing:6){
                HStack{ Image(systemName:"music.note"); Text(entry.title).font(.caption.weight(.semibold)).lineLimit(1) }
                Text(entry.free).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
struct TuneTorrentWidget: Widget {
    let kind = "TuneTorrentWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:kind, provider:Provider()){ e in WidgetEntryView(entry:e).containerBackground(.fill.tertiary, for:.widget) }
        .configurationDisplayName("Now Playing").description("Shows current song and free space").supportedFamilies([.systemSmall,.systemMedium])
    }
}
