import SwiftUI
import AVFoundation
import AVKit

// MARK: - MiniPlayerView (glassy floating)
struct MiniPlayerView: View {
    var onTap: () -> Void = {}
    @ObservedObject private var playback = PlaybackService.shared

    var body: some View {
        if playback.currentTitle != "Not Playing" || playback.isPlaying || playback.currentSong != nil {
            GlassCard {
                HStack(spacing: 12) {
                    Group {
                        if let data = playback.currentArtwork, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Theme.accentGradient)
                                Image(systemName: "music.note")
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 44, height: 44)
                        }
                    }
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(playback.currentTitle)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if !playback.currentArtist.isEmpty {
                            Text(playback.currentArtist)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        ProgressView(value: playback.progress)
                            .tint(Theme.accent)
                            .scaleEffect(x: 1, y: 0.7, anchor: .center)
                    }

                    Spacer()

                    Button(action: { playback.toggle() }) {
                        Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.callout.weight(.semibold))
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Theme.glassStroke, lineWidth: 0.6))
                    }
                    .accessibilityLabel(playback.isPlaying ? "Pause" : "Play")

                    Button(action: { playback.next() }) {
                        Image(systemName: "forward.fill")
                            .font(.callout)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Next")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
            .onTapGesture { onTap() }
            .accessibilityLabel("Mini player")
        }
    }
}

// MARK: - FullPlayerView (glassy)
struct FullPlayerView: View {
    @ObservedObject private var playback = PlaybackService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showLyrics = false
    @State private var showEQ = false
    @State private var sleepOn = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    Group {
                        if let data = playback.currentArtwork, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 280, height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Theme.accent.opacity(0.35), radius: 24, y: 12)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Theme.accentGradient)
                                    .frame(width: 280, height: 280)
                                    .shadow(color: Theme.accent.opacity(0.35), radius: 24, y: 12)
                                Image(systemName: "music.note")
                                    .font(.system(size: 72, weight: .thin))
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                        }
                    }
                    .padding(.top, 12)

                    VStack(spacing: 4) {
                        Text(playback.currentTitle)
                            .font(.title2.weight(.heavy))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text(playback.currentArtist.isEmpty ? (playback.currentSong?.artist ?? "TuneTorrent") : playback.currentArtist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    GlassCard {
                        VStack(spacing: 8) {
                            Slider(value: Binding(get: { playback.progress }, set: { playback.seek(to: $0 * playback.duration) }), in: 0...1)
                                .tint(Theme.accent)
                            HStack {
                                Text(Formatters.duration(playback.progress * playback.duration))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(Formatters.duration(playback.duration))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack(spacing: 24) {
                        Button {
                            playback.shuffle.toggle()
                        } label: {
                            Image(systemName: playback.shuffle ? "shuffle.circle.fill" : "shuffle")
                                .font(.title3)
                                .foregroundStyle(playback.shuffle ? Theme.accent : .secondary)
                        }

                        Button {
                            playback.prev()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                        }

                        Button {
                            playback.toggle()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Theme.accentGradient)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 6)
                                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                            }
                        }
                        .accessibilityLabel(playback.isPlaying ? "Pause" : "Play")

                        Button {
                            playback.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                        }
                        .accessibilityLabel("Next")

                        Button {
                            playback.cycleRepeat()
                        } label: {
                            Image(systemName: playback.repeatIcon)
                                .font(.title3)
                                .foregroundStyle(playback.repeatMode == .off ? .secondary : Theme.accent)
                        }
                    }

                    HStack(spacing: 12) {
                        LiquidGlassButton(title: playback.isFavorite ? "Favorited" : "Favorite", systemImage: playback.isFavorite ? "heart.fill" : "heart") {
                            playback.isFavorite.toggle()
                            playback.currentSong?.isFavorite = playback.isFavorite
                        }
                        LiquidGlassButton(title: "Lyrics", systemImage: "music.mic") {
                            showLyrics.toggle()
                        }
                        LiquidGlassButton(title: "EQ", systemImage: "slider.horizontal.3") {
                            showEQ.toggle()
                        }
                        Spacer()
                        AirPlayView().frame(width: 28, height: 28)
                    }

                    if showLyrics {
                        LyricsView(lyrics: playback.currentSong?.lyrics ?? "No synced lyrics found for this track.")
                    }
                    if showEQ {
                        EqualizerView()
                    }

                    SleepTimerView(isOn: $sleepOn) { mins in
                        playback.setSleepTimer(minutes: mins)
                    }

                    if !playback.queue.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Up Next (\(playback.queue.count))")
                                    .font(.caption.weight(.semibold))
                                Spacer()
                            }
                            GlassCard {
                                ForEach(playback.queue.prefix(6), id: \.id) { s in
                                    HStack {
                                        Text(s.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundStyle(s.id == playback.currentSong?.id ? Theme.accent : .primary)
                                        Spacer()
                                        Text(s.artist)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    .padding(.vertical, 3)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        playback.play(s, queue: playback.queue)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - AirPlayView
struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView { AVRoutePickerView() }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
