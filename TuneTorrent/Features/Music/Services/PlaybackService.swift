import AVFoundation
import MediaPlayer
import Combine

// MARK: - PlaybackService
@MainActor
final class PlaybackService: ObservableObject {
    static let shared = PlaybackService()
    private let player = AVQueuePlayer()
    @Published var isPlaying = false
    @Published var currentTitle = "Not Playing"
    @Published var progress: Double = 0
    @Published var duration: Double = 0
    @Published var queue: [Song] = []
    @Published var shuffle = false
    @Published var repeatMode: RepeatMode = .off

    enum RepeatMode { case off, one, all }

    init() { setupAudioSession(); setupRemoteCommands(); observe() }

    private func setupAudioSession() {
        do { try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default); try AVAudioSession.sharedInstance().setActive(true) } catch { print("AudioSession failed \(error)") }
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
            guard let info = n.userInfo, let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
            Task { @MainActor in if type == .began { self?.player.pause() } else if type == .ended { self?.player.play() } }
        }
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.player.play(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.player.pause(); return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.prev(); return .success }
    }

    private func observe() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let item = self.player.currentItem else { return }
                self.progress = self.duration > 0 ? item.currentTime().seconds / self.duration : 0
                self.isPlaying = self.player.timeControlStatus == .playing
            }
        }
    }

    func play(_ song: Song, queue: [Song]) {
        player.removeAllItems()
        self.queue = queue
        guard let url = song.url else { return }
        let item = AVPlayerItem(url: url)
        player.insert(item, after: nil)
        duration = song.duration
        currentTitle = song.title
        updateNowPlaying(song: song)
        LiveActivityService.startMusic(title: song.title, artist: song.artist)
        player.play(); isPlaying = true
    }

    private func updateNowPlaying(song: Song) {
        var info: [String: Any] = [MPMediaItemPropertyTitle: song.title, MPMediaItemPropertyArtist: song.artist, MPMediaItemPropertyAlbumTitle: song.album]
        if let data = song.artworkData, let img = UIImage(data: data) { info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img } }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func toggle() { isPlaying ? pause() : resume() }
    func pause() { player.pause(); isPlaying = false }
    func resume() { player.play(); isPlaying = true }
    private var currentSongIndex: Int? {
        queue.firstIndex(where: { $0.title == currentTitle })
    }

    func next() {
        if let idx = currentSongIndex, idx + 1 < queue.count {
            play(queue[idx + 1], queue: queue)
        } else {
            player.advanceToNextItem()
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
    func seek(to seconds: Double) { player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600)) }
    func seek(toRatio ratio: Double) { seek(to: ratio * duration) }
    var repeatIcon: String { switch repeatMode { case .off: return "repeat"; case .one: return "repeat.1"; case .all: return "repeat.circle.fill" } }
    func cycleRepeat() { repeatMode = repeatMode == .off ? .all : repeatMode == .all ? .one : .off }
    func shuffleQueue(_ on: Bool) { shuffle = on }
    @Published var isFavorite = false
    private var sleepWorkItem: DispatchWorkItem?
    func setSleepTimer(minutes: Int) {
        sleepWorkItem?.cancel()
        let w = DispatchWorkItem { [weak self] in Task { @MainActor in self?.pause() } }
        sleepWorkItem = w; DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minutes*60), execute: w)
    }
}
