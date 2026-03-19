import AVFoundation
import Foundation

final class AVMediaPlayerService: MediaPlayerServiceProtocol, @unchecked Sendable {
    private var player: AVPlayer?
    private var preferredRate: Float = 1.0

    var avPlayer: AVPlayer? {
        player
    }

    var currentTime: Double {
        guard let seconds = player?.currentTime().seconds, seconds.isFinite else { return 0 }
        return seconds
    }

    var duration: Double {
        guard let seconds = player?.currentItem?.duration.seconds, seconds.isFinite else { return 0 }
        return seconds
    }

    var isPlaying: Bool {
        (player?.rate ?? 0) > 0
    }

    func loadMedia(url: URL) async throws {
        player = AVPlayer(url: url)
    }

    func play() async {
        guard let player else { return }
        if preferredRate == 1.0 {
            player.play()
        } else {
            player.playImmediately(atRate: preferredRate)
        }
    }

    func pause() async {
        player?.pause()
    }

    func seek(to timeSeconds: Double) async {
        let clamped = max(0, timeSeconds)
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        await player?.seek(to: time)
    }

    func setPlaybackRate(_ rate: Float) async {
        guard rate > 0 else { return }
        preferredRate = rate
        guard isPlaying else { return }
        player?.rate = rate
        if let player, player.rate == 0 {
            player.playImmediately(atRate: rate)
        }
    }
}
