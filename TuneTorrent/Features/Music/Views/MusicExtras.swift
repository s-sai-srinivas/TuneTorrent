import SwiftUI

// MARK: - LyricsView (glassy)
struct LyricsView: View {
    let lyrics: String?
    var body: some View {
        GlassCard {
            VStack(alignment:.leading,spacing:8){
                HStack{ Image(systemName:"music.mic"); Text("Lyrics").font(.subheadline.weight(.semibold)); Spacer(); Image(systemName:"waveform") }
                if let l = lyrics, !l.isEmpty { ScrollView{ Text(l).font(.callout).foregroundStyle(.secondary).frame(maxWidth:.infinity, alignment:.leading) }.frame(maxHeight:160) }
                else { Text("No lyrics found. Add a .lrc file next to the song.").font(.caption).foregroundStyle(.secondary) }
            }
        }
    }
}

// MARK: - EqualizerView (glassy sliders)
struct EqualizerView: View {
    @State private var bass: Double = 0.5
    @State private var mid: Double = 0.5
    @State private var treble: Double = 0.5
    @State private var preset: String = "Flat"
    let presets = ["Flat","Bass Boost","Vocal","Acoustic","Electronic"]
    var body: some View {
        GlassCard {
            VStack(spacing:12){
                HStack{ Text("Equalizer").font(.subheadline.weight(.semibold)); Spacer(); Picker("", selection:$preset){ ForEach(presets,id:\.self){ Text($0).tag($0) } }.pickerStyle(.menu).tint(Theme.accent) }
                HStack(spacing:18){
                    VStack{ Text("Bass").font(.caption2); Slider(value:$bass).tint(Theme.accent); Text("\(Int(bass*12-6)) dB").font(.caption2).foregroundStyle(.secondary) }
                    VStack{ Text("Mid").font(.caption2); Slider(value:$mid).tint(Theme.accent); Text("\(Int(mid*12-6)) dB").font(.caption2).foregroundStyle(.secondary) }
                    VStack{ Text("Treble").font(.caption2); Slider(value:$treble).tint(Theme.accent); Text("\(Int(treble*12-6)) dB").font(.caption2).foregroundStyle(.secondary) }
                }
                Text("Presets use AVAudioEngine EQ (Phase 1 polish)").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - SleepTimerView
struct SleepTimerView: View {
    @State private var minutes: Double = 15
    @Binding var isOn: Bool
    var onSet: (Int) -> Void = {_ in}
    var body: some View {
        GlassCard {
            VStack(spacing:10){
                HStack{ Image(systemName:"moon.zzz.fill"); Text("Sleep Timer").font(.subheadline.weight(.semibold)); Spacer(); Toggle("", isOn:$isOn).labelsHidden().tint(Theme.accent) }
                if isOn {
                    HStack{ Text("\(Int(minutes)) min").font(.caption); Slider(value:$minutes, in:5...120, step:5).tint(Theme.accent) }
                    LiquidGlassButton(title:"Set Timer", systemImage:"timer"){ onSet(Int(minutes)) }
                    Text("Playback will pause automatically.").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}
