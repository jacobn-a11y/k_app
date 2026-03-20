import Testing
import Foundation
@testable import HallyuCore

@Suite("MediaTranscriptionService Tests")
struct MediaTranscriptionServiceTests {

    // MARK: - Mock Speech Service

    final class MockSpeechService: SpeechRecognitionServiceProtocol, @unchecked Sendable {
        var isAvailable: Bool = true
        var shouldAuthorize: Bool = true
        var mockResult: SpeechRecognitionResult?
        var shouldThrow: Error?

        func requestAuthorization() async -> Bool {
            shouldAuthorize
        }

        func recognizeSpeech(from audioURL: URL) async throws -> SpeechRecognitionResult {
            if let error = shouldThrow {
                throw error
            }
            return mockResult ?? SpeechRecognitionResult(
                transcript: "",
                confidence: 0.0,
                segments: []
            )
        }
    }

    // MARK: - canTranscribe

    @Test("canTranscribe returns true for short media")
    func canTranscribeShort() {
        #expect(MediaTranscriptionService.canTranscribe(durationSeconds: 30))
        #expect(MediaTranscriptionService.canTranscribe(durationSeconds: 60))
    }

    @Test("canTranscribe returns false for long or zero-length media")
    func canTranscribeLong() {
        #expect(!MediaTranscriptionService.canTranscribe(durationSeconds: 61))
        #expect(!MediaTranscriptionService.canTranscribe(durationSeconds: 300))
        #expect(!MediaTranscriptionService.canTranscribe(durationSeconds: 0))
    }

    // MARK: - Transcription

    @Test("Transcribes audio and converts segments")
    func transcribesAudio() async throws {
        let mock = MockSpeechService()
        mock.mockResult = SpeechRecognitionResult(
            transcript: "안녕하세요 오늘 날씨가 좋아요",
            confidence: 0.9,
            segments: [
                SpeechSegment(text: "안녕하세요", confidence: 0.95, timestamp: 0.0, duration: 1.5),
                SpeechSegment(text: "오늘", confidence: 0.9, timestamp: 1.5, duration: 0.5),
                SpeechSegment(text: "날씨가", confidence: 0.85, timestamp: 2.0, duration: 0.7),
                SpeechSegment(text: "좋아요", confidence: 0.92, timestamp: 2.7, duration: 0.8),
            ]
        )

        let service = MediaTranscriptionService(speechService: mock)
        let result = try await service.transcribe(
            mediaURL: URL(string: "file:///test.m4a")!,
            durationSeconds: 10
        )

        #expect(result.transcriptKr == "안녕하세요 오늘 날씨가 좋아요")
        #expect(result.confidence == 0.9)
        #expect(!result.segments.isEmpty)
        // Segments are consolidated, so check first segment starts at 0
        #expect(result.segments[0].startMs == 0)
    }

    @Test("Throws mediaTooLong for long content")
    func throwsForLongContent() async {
        let mock = MockSpeechService()
        let service = MediaTranscriptionService(speechService: mock)

        await #expect(throws: MediaTranscriptionService.TranscriptionError.self) {
            try await service.transcribe(
                mediaURL: URL(string: "file:///test.m4a")!,
                durationSeconds: 120
            )
        }
    }

    @Test("Throws notAuthorized when speech recognition denied")
    func throwsForUnauthorized() async {
        let mock = MockSpeechService()
        mock.shouldAuthorize = false
        let service = MediaTranscriptionService(speechService: mock)

        await #expect(throws: MediaTranscriptionService.TranscriptionError.self) {
            try await service.transcribe(
                mediaURL: URL(string: "file:///test.m4a")!,
                durationSeconds: 30
            )
        }
    }

    @Test("Throws emptyResult when no transcript produced")
    func throwsForEmptyResult() async {
        let mock = MockSpeechService()
        mock.mockResult = SpeechRecognitionResult(
            transcript: "",
            confidence: 0.0,
            segments: []
        )
        let service = MediaTranscriptionService(speechService: mock)

        await #expect(throws: MediaTranscriptionService.TranscriptionError.self) {
            try await service.transcribe(
                mediaURL: URL(string: "file:///test.m4a")!,
                durationSeconds: 30
            )
        }
    }
}
