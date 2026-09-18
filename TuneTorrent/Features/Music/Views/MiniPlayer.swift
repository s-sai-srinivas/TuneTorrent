import SwiftUI
import AVFoundation

// MARK: - MiniPlayerView (glassy floating)
struct MiniPlayerView: View {
    var onTap: () -> Void = {}
    @ObservedObject private var playback = PlaybackService.shared
    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                ZStack{ RoundedRectangle(cornerRadius: 10, style:.continuous).fill(Theme.accentGradient); Image(systemName:"music.note").foregroundStyle(.white) }.frame(width: 44, height: 44).shadow(color:.black.opacity(0.15), radius:6, y:3)
                VStack(alignment: .leading, spacing:3) { Text(playback.currentTitle).font(.subheadline.weight(.semibold)).lineLimit(1); ProgressView(value: playback.progress).tint(Theme.accent).scaleEffect(x:1,y:0.7,anchor:.center) }
                Spacer()
                Button(action: { playback.toggle() }) { Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill").font(.callout.weight(.semibold)).frame(width:32,height:32).background(.ultraThinMaterial, in: Circle()).overlay(Circle().stroke(Theme.glassStroke,lineWidth:0.6)) }
                Button(action: { playback.next() }) { Image(systemName: "forward.fill").font(.caption) }
            }
        }
        .padding(.horizontal).padding(.bottom, 6).onTapGesture { onTap() }
        .accessibilityLabel("Mini player")
    }
}

// MARK: - FullPlayerView (glassy)
struct FullPlayerView: View {
    @ObservedObject private var playback = PlaybackService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showLyrics = true
    @State private var showEQ = false
    @State private var sleepOn = false
    @State private var currentLyrics: String? = "Line 1 — We are tunetorrent\nLine 2 — Glass like iPhone 18\n(Real lyrics load from .lrc or AVAsset)"
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ZStack{
                        RoundedRectangle(cornerRadius: 28, style:.continuous).fill(Theme.accentGradient).frame(width: 300, height: 300).shadow(color:Theme.accent.opacity(0.35), radius:24, y:12)
                        Image(systemName: "music.note").font(.system(size: 72, weight:.thin)).foregroundStyle(.white.opacity(0.95))
                    }.padding(.top, 10)
                    Text(playback.currentTitle).font(.title2.weight(.heavy)).multilineTextAlignment(.center)
                    Text(playback.queue.first?.artist ?? "TuneTorrent").font(.subheadline).foregroundStyle(.secondary)
                    GlassCard{
                        VStack(spacing:8){
                            Slider(value: Binding(get:{playback.progress}, set:{playback.seek(to: $0 * playback.duration)}), in:0...1).tint(Theme.accent)
                            HStack{ Text(Formatters.duration(playback.progress*playback.duration)).font(.caption2).foregroundStyle(.secondary); Spacer(); Text(Formatters.duration(playback.duration)).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                    HStack(spacing: 18) {
                        Button { playback.shuffle.toggle() } label: { Image(systemName: playback.shuffle ? "shuffle.circle.fill" : "shuffle").font(.title3).foregroundStyle(playback.shuffle ? Theme.accent : .secondary) }
                        Button { playback.prev() } label: { Image(systemName: "backward.fill").font(.title2) }
                        Button { playback.toggle() } label: { ZStack{ Circle().fill(Theme.accentGradient).frame(width:64,height:64).shadow(color:Theme.accent.opacity(0.4), radius:12, y:6); Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill").foregroundStyle(.white).font(.title2) } }
                        Button { playback.next() } label: { Image(systemName: "forward.fill").font(.title2) }
                        Button { playback.cycleRepeat() } label: { Image(systemName: playback.repeatIcon).font(.title3).foregroundStyle(playback.repeatMode == .off ? .secondary : Theme.accent) }
                    }
                    HStack{
                        LiquidGlassButton(title: playback.isFavorite ? "Favorited" : "Favorite", systemImage: playback.isFavorite ? "heart.fill" : "heart"){ playback.isFavorite.toggle() }
                        LiquidGlassButton(title:"Lyrics", systemImage:"music.mic"){ showLyrics.toggle() }
                        LiquidGlassButton(title:"EQ", systemImage:"slider.horizontal.3"){ showEQ.toggle() }
                        Spacer(); AirPlayView().frame(width:28,height:28)
                    }
                    if showLyrics { LyricsView(lyrics: currentLyrics) }
                    if showEQ { EqualizerView() }
                    SleepTimerView(isOn:$sleepOn){ mins in playback.setSleepTimer(minutes: mins) }
                    HStack{ Text("Queue (\(playback.queue.count))").font(.caption.weight(.semibold)); Spacer(); Text("Shuffle • Repeat \(playback.repeatMode == .off ? "Off" : playback.repeatMode == .all ? "All" : "One")").font(.caption2).foregroundStyle(.secondary) }
                    if !playback.queue.isEmpty { GlassCard{ ForEach(playback.queue.prefix(5), id:\.id){ s in HStack{ Text(s.title).font(.caption); Spacer(); Text(s.artist).font(.caption2).foregroundStyle(.secondary) } } } }
                }.padding()
            }.background(Theme.background).toolbar{ ToolbarItem(placement:.cancellationAction){ Button("Close"){dismiss()} } }
        }
    }
}

// MARK: - AirPlayView
struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView { AVRoutePickerView() }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
