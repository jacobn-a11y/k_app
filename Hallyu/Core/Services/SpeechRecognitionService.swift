import Foundation
import Speech

actor SpeechRecognitionService: SpeechRecognitionServiceProtocol {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?

    nonisolated var isAvailable: Bool {
        SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))?.isAvailable ?? false
    }

    init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    }

    nonisolated func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    nonisolated func recognizeSpeech(from audioURL: URL) async throws -> SpeechRecognitionResult {
        try await _recognizeSpeech(from: audioURL)
    }

    private func _recognizeSpeech(from audioURL: URL) async throws -> SpeechRecognitionResult {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechRecognitionError.notAvailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        return try await withCheckedThrowingContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: SpeechRecognitionError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let result = result, result.isFinal else { return }

                let bestTranscription = result.bestTranscription
                let segments = bestTranscription.segments.map { segment in
                    SpeechSegment(
                        text: segment.substring,
                        confidence: Double(segment.confidence),
                        timestamp: segment.timestamp,
                        duration: segment.duration
                    )
                }

                let overallConfidence: Double
                if segments.isEmpty {
                    overallConfidence = 0.0
                } else {
                    overallConfidence = segments.reduce(0.0) { $0 + $1.confidence } / Double(segments.count)
                }

                let speechResult = SpeechRecognitionResult(
                    transcript: bestTranscription.formattedString,
                    confidence: overallConfidence,
                    segments: segments
                )

                self.cleanupTemporaryRecordingIfNeeded(at: audioURL)
                continuation.resume(returning: speechResult)
            }
        }
    }

    func cancelRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    nonisolated private func cleanupTemporaryRecordingIfNeeded(at url: URL) {
        guard url.path.contains("/HallyuRecordings/") else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

enum SpeechRecognitionError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case recognitionFailed(String)
    case noResult

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Korean speech recognition not available"
        case .notAuthorized: return "Speech recognition not authorized"
        case .recognitionFailed(let reason): return "Recognition failed: \(reason)"
        case .noResult: return "No recognition result"
        }
    }
}
