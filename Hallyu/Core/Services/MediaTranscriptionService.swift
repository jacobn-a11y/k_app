import Foundation

/// Transcribes audio/video media into Korean text using the device's speech recognition.
/// Converts SpeechRecognitionResult segments into MediaContent.TranscriptSegment format.
actor MediaTranscriptionService {

    struct TranscriptionResult: Sendable {
        let transcriptKr: String
        let segments: [MediaContent.TranscriptSegment]
        let confidence: Double
    }

    enum TranscriptionError: Error, LocalizedError {
        case notAuthorized
        case mediaTooLong(durationSeconds: Int)
        case emptyResult

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Speech recognition not authorized"
            case .mediaTooLong(let duration):
                return "Media is too long for on-device transcription (\(duration)s). Provide captions externally."
            case .emptyResult:
                return "Transcription produced no text"
            }
        }
    }

    /// Apple's on-device speech recognition is limited to ~1 minute of audio.
    static let maxDurationSeconds = 60

    private let speechService: SpeechRecognitionServiceProtocol

    init(speechService: SpeechRecognitionServiceProtocol) {
        self.speechService = speechService
    }

    /// Transcribe a local audio/video file and return Korean transcript with timestamps.
    /// Throws `mediaTooLong` if the file exceeds the on-device recognition limit.
    func transcribe(mediaURL: URL, durationSeconds: Int) async throws -> TranscriptionResult {
        guard durationSeconds <= Self.maxDurationSeconds else {
            throw TranscriptionError.mediaTooLong(durationSeconds: durationSeconds)
        }

        let authorized = await speechService.requestAuthorization()
        guard authorized else {
            throw TranscriptionError.notAuthorized
        }

        let speechResult = try await speechService.recognizeSpeech(from: mediaURL)

        guard !speechResult.transcript.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        let segments = speechResult.segments.map { segment in
            MediaContent.TranscriptSegment(
                startMs: Int(segment.timestamp * 1000),
                endMs: Int((segment.timestamp + segment.duration) * 1000),
                textKr: segment.text,
                textEn: ""
            )
        }

        // Consolidate word-level segments into sentence-like chunks for better usability.
        let consolidated = consolidateSegments(segments)

        return TranscriptionResult(
            transcriptKr: speechResult.transcript,
            segments: consolidated,
            confidence: speechResult.confidence
        )
    }

    /// Check whether a media item is eligible for on-device transcription.
    nonisolated static func canTranscribe(durationSeconds: Int) -> Bool {
        durationSeconds > 0 && durationSeconds <= maxDurationSeconds
    }

    // MARK: - Private

    /// Consolidate word-level segments into larger chunks (~3-5 seconds each)
    /// for a more natural reading/shadowing experience.
    private func consolidateSegments(
        _ segments: [MediaContent.TranscriptSegment],
        targetChunkMs: Int = 4000
    ) -> [MediaContent.TranscriptSegment] {
        guard !segments.isEmpty else { return [] }

        var consolidated: [MediaContent.TranscriptSegment] = []
        var currentText = ""
        var chunkStartMs = segments[0].startMs
        var lastEndMs = segments[0].startMs

        for segment in segments {
            let chunkDuration = segment.endMs - chunkStartMs
            if chunkDuration >= targetChunkMs && !currentText.isEmpty {
                consolidated.append(MediaContent.TranscriptSegment(
                    startMs: chunkStartMs,
                    endMs: lastEndMs,
                    textKr: currentText.trimmingCharacters(in: .whitespaces),
                    textEn: ""
                ))
                currentText = segment.textKr
                chunkStartMs = segment.startMs
            } else {
                currentText += currentText.isEmpty ? segment.textKr : " \(segment.textKr)"
            }
            lastEndMs = segment.endMs
        }

        // Flush remaining text
        if !currentText.isEmpty {
            consolidated.append(MediaContent.TranscriptSegment(
                startMs: chunkStartMs,
                endMs: lastEndMs,
                textKr: currentText.trimmingCharacters(in: .whitespaces),
                textEn: ""
            ))
        }

        return consolidated
    }
}
