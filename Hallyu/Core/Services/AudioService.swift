import AVFoundation
import Foundation

actor AudioService: AudioServiceProtocol {
    private final class PublicState: @unchecked Sendable {
        private let lock = NSLock()
        private var _isRecording = false
        private var _isPlaying = false

        var isRecording: Bool {
            lock.lock()
            defer { lock.unlock() }
            return _isRecording
        }

        var isPlaying: Bool {
            lock.lock()
            defer { lock.unlock() }
            return _isPlaying
        }

        func setRecording(_ value: Bool) {
            lock.lock()
            _isRecording = value
            lock.unlock()
        }

        func setPlaying(_ value: Bool) {
            lock.lock()
            _isPlaying = value
            lock.unlock()
        }
    }

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private nonisolated let publicState = PublicState()

    nonisolated var isRecording: Bool {
        publicState.isRecording
    }

    nonisolated var isPlaying: Bool {
        publicState.isPlaying
    }

    nonisolated func startRecording() async throws -> URL {
        try await _startRecording()
    }

    nonisolated func stopRecording() async throws -> URL {
        try await _stopRecording()
    }

    nonisolated func playAudio(url: URL) async throws {
        try await _playAudio(url: url)
    }

    nonisolated func stopPlayback() async {
        await _stopPlayback()
    }

    // MARK: - Actor-isolated implementations

    private func _startRecording() throws -> URL {
        #if os(iOS) || os(tvOS) || os(watchOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        #endif

        let fileManager = FileManager.default
        let cachesPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let recordingsDir = cachesPath.appendingPathComponent("HallyuRecordings", isDirectory: true)
        if !fileManager.fileExists(atPath: recordingsDir.path) {
            try fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
            #if os(iOS) || os(tvOS) || os(watchOS)
            try? fileManager.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: recordingsDir.path
            )
            #endif
        }
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let url = recordingsDir.appendingPathComponent(fileName)
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        #if os(iOS) || os(tvOS) || os(watchOS)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
        #endif
        publicState.setRecording(true)

        return url
    }

    private func _stopRecording() throws -> URL {
        guard let recorder = audioRecorder, let url = recordingURL else {
            throw AudioServiceError.notRecording
        }

        recorder.stop()
        audioRecorder = nil
        publicState.setRecording(false)

        return url
    }

    private func _playAudio(url: URL) throws {
        #if os(iOS) || os(tvOS) || os(watchOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback)
        try audioSession.setActive(true)
        #endif

        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
        publicState.setPlaying(true)
    }

    private func _stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        publicState.setPlaying(false)
    }
}

enum AudioServiceError: Error, LocalizedError {
    case notRecording
    case notPlaying
    case recordingFailed
    case playbackFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notRecording: return "Not currently recording"
        case .notPlaying: return "Not currently playing"
        case .recordingFailed: return "Recording failed"
        case .playbackFailed: return "Playback failed"
        case .permissionDenied: return "Microphone permission denied"
        }
    }
}
