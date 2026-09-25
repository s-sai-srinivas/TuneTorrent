import AVFoundation
import MediaPlayer
import Combine
import UIKit

// MARK: - PlaybackService
@MainActor
final class PlaybackService: ObservableObject {
    static let shared = PlaybackService()
    private let player = AVQueuePlayer()
    
    @Published var isPlaying = false
    @Published var currentTitle = "Not Playing"
    @Published var currentArtist = ""
    @Published var currentAlbum = ""
    @Published var currentArtwork: Data? = nil
    @Published var currentSong: Song? = nil
    @Published var progress: Double = 0
    @Published var duration: Double = 0
    @Published var queue: [Song] = []
    @Published var shuffle = false
    @Published var repeatMode: RepeatMode = .off
    @Published var isFavorite = false

    enum RepeatMode { case off, one, all }

    private var timeObserverToken: Any?
    private var sleepWorkItem: DispatchWorkItem?

    init() {
        setupAudioSession()
        setupRemoteCommands()
        observe()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[PlaybackService] AudioSession setup failed: \(error)")
        }

        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
            guard let info = n.userInfo,
                  let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
            Task { @MainActor in
                if type == .began {
                    self?.pause()
                } else if type == .ended {
                    self?.resume()
                }
            }
        }

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.next()
            }
        }
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.resume(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.prev(); return .success }
    }

    private func observe() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let item = self.player.currentItem else { return }
                let currentTime = item.currentTime().seconds
                if currentTime.isFinite && self.duration > 0 {
                    self.progress = max(0, min(1, currentTime / self.duration))
                }
                self.isPlaying = (self.player.timeControlStatus == .playing)
            }
        }
    }

    func play(_ song: Song, queue: [Song]) {
        player.removeAllItems()
        self.queue = queue
        self.currentSong = song
        self.currentTitle = song.title
        self.currentArtist = song.artist
        self.currentAlbum = song.album
        self.currentArtwork = song.artworkData
        self.duration = song.duration
        self.isFavorite = song.isFavorite

        guard let url = song.url else {
            print("[PlaybackService] Cannot play song, invalid url for \(song.title)")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[PlaybackService] Failed to activate audio session: \(error)")
        }

        let item = AVPlayerItem(url: url)
        player.insert(item, after: nil)

        // Asynchronously inspect real duration if needed
        Task {
            if let d = try? await item.asset.load(.duration) {
                let s = d.seconds
                if s > 0 && !s.isNaN && !s.isInfinite {
                    self.duration = s
                    song.duration = s
                }
            }
        }

        updateNowPlaying(song: song)
        LiveActivityService.startMusic(title: song.title, artist: song.artist)
        player.play()
        isPlaying = true
    }

    private func updateNowPlaying(song: Song) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album
        ]
        if song.duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = song.duration
        }
        if let data = song.artworkData, let img = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func toggle() { isPlaying ? pause() : resume() }
    func pause() { player.pause(); isPlaying = false }
    func resume() {
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play()
        isPlaying = true
    }

    private var currentSongIndex: Int? {
        queue.firstIndex(where: { $0.id == currentSong?.id || $0.title == currentTitle })
    }

    func next() {
        guard !queue.isEmpty else { return }

        if repeatMode == .one, let current = currentSong {
            seek(to: 0)
            resume()
            return
        }

        if shuffle {
            if let randomSong = queue.randomElement() {
                play(randomSong, queue: queue)
            }
            return
        }

        if let idx = currentSongIndex {
            if idx + 1 < queue.count {
                play(queue[idx + 1], queue: queue)
            } else if repeatMode == .all {
                play(queue[0], queue: queue)
            } else {
                pause()
                seek(to: 0)
            }
        } else if let first = queue.first {
            play(first, queue: queue)
        }
    }

    func prev() {
        if let currentItem = player.currentItem, currentItem.currentTime().seconds > 3.0 {
            seek(to: 0)
            return
        }
        guard let idx = currentSongIndex, idx > 0 else {
            seek(to: 0)
            return
        }
        play(queue[idx - 1], queue: queue)
    }

    func seek(to seconds: Double) {
        let validSec = max(0, min(seconds, duration))
        player.seek(to: CMTime(seconds: validSec, preferredTimescale: 600))
    }

    func seek(toRatio ratio: Double) {
        seek(to: ratio * duration)
    }

    var repeatIcon: String {
        switch repeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat.circle.fill"
        }
    }

    func cycleRepeat() {
        repeatMode = repeatMode == .off ? .all : repeatMode == .all ? .one : .off
    }

    func shuffleQueue(_ on: Bool) { shuffle = on }

    func setSleepTimer(minutes: Int) {
        sleepWorkItem?.cancel()
        let w = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.pause()
            }
        }
        sleepWorkItem = w
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minutes * 60), execute: w)
    }
}
