import AVFoundation
import Foundation

final class AVMediaPlayerService: MediaPlayerServiceProtocol, @unchecked Sendable {
    private let stateQueue = DispatchQueue(label: "com.hallyu.media-player-state")
    private var player: AVPlayer?
    private var _currentTime: Double = 0
    private var _duration: Double = 0
    private var _isPlaying: Bool = false

    var currentTime: Double {
        stateQueue.sync { _currentTime }
    }

    var duration: Double {
        stateQueue.sync { _duration }
    }

    var isPlaying: Bool {
        stateQueue.sync { _isPlaying }
    }

    func loadMedia(url: URL) async throws {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)

        await MainActor.run {
            let item = AVPlayerItem(asset: asset)
            if player == nil {
                player = AVPlayer(playerItem: item)
            } else {
                player?.replaceCurrentItem(with: item)
            }
        }

        stateQueue.sync {
            _duration = duration.seconds.isFinite ? duration.seconds : 0
            _currentTime = 0
            _isPlaying = false
        }
    }

    func play() async {
        await MainActor.run {
            player?.play()
        }

        stateQueue.sync {
            _isPlaying = true
        }
    }

    func pause() async {
        await MainActor.run {
            player?.pause()
        }

        stateQueue.sync {
            _isPlaying = false
        }
    }

    func seek(to timeSeconds: Double) async {
        let target = max(0, timeSeconds)
        await MainActor.run {
            let cmTime = CMTime(seconds: target, preferredTimescale: 600)
            player?.seek(to: cmTime)
        }

        stateQueue.sync {
            _currentTime = target
        }
    }

    func setPlaybackRate(_ rate: Float) async {
        await MainActor.run {
            guard let player else { return }
            if player.timeControlStatus == .playing {
                player.rate = rate
            } else {
                player.currentItem?.audioTimePitchAlgorithm = .timeDomain
            }
        }
    }
}
