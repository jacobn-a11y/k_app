import AVFoundation
import Foundation

actor AudioService: AudioServiceProtocol {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?

    nonisolated var isRecording: Bool {
        false // Checked via state in the actor
    }

    nonisolated var isPlaying: Bool {
        false
    }

    private var _isRecording: Bool = false
    private var _isPlaying: Bool = false

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
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let url = documentsPath.appendingPathComponent(fileName)
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        _isRecording = true

        return url
    }

    private func _stopRecording() throws -> URL {
        guard let recorder = audioRecorder, let url = recordingURL else {
            throw AudioServiceError.notRecording
        }

        recorder.stop()
        audioRecorder = nil
        _isRecording = false

        return url
    }

    private func _playAudio(url: URL) throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback)
        try audioSession.setActive(true)

        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
        _isPlaying = true
    }

    private func _stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        _isPlaying = false
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
