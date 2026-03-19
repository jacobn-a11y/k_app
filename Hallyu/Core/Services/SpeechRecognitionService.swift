import Foundation
import Speech

actor SpeechRecognitionService: SpeechRecognitionServiceProtocol {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognitionTimeoutNanos: UInt64 = 12_000_000_000

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

        defer {
            cleanupTemporaryRecordingIfNeeded(at: audioURL)
        }

        return try await withThrowingTaskGroup(of: SpeechRecognitionResult.self) { group in
            group.addTask { [weak self] in
                guard let self else { throw SpeechRecognitionError.notAvailable }
                return try await self.runRecognitionTask(recognizer: recognizer, request: request)
            }

            group.addTask { [timeout = recognitionTimeoutNanos] in
                try await Task.sleep(nanoseconds: timeout)
                throw SpeechRecognitionError.timeout
            }

            guard let firstCompleted = try await group.next() else {
                throw SpeechRecognitionError.noResult
            }

            group.cancelAll()
            await cancelRecognition()
            return firstCompleted
        }
    }

    private func runRecognitionTask(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechURLRecognitionRequest
    ) async throws -> SpeechRecognitionResult {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let resolver = ContinuationResolver(continuation: continuation)

                recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                    if let error {
                        resolver.resume(with: .failure(SpeechRecognitionError.recognitionFailed(error.localizedDescription)))
                        return
                    }

                    guard let result else { return }
                    guard result.isFinal else { return }

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

                    resolver.resume(with: .success(speechResult))
                }
            }
        }, onCancel: {
            Task { await self.cancelRecognition() }
        })
    }

    func cancelRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    nonisolated private func cleanupTemporaryRecordingIfNeeded(at url: URL) {
        guard url.path.contains("/HallyuRecordings/") || url.path.contains("recording_") else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

enum SpeechRecognitionError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case recognitionFailed(String)
    case noResult
    case timeout

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Korean speech recognition not available"
        case .notAuthorized: return "Speech recognition not authorized"
        case .recognitionFailed(let reason): return "Recognition failed: \(reason)"
        case .noResult: return "No recognition result"
        case .timeout: return "Speech recognition timed out"
        }
    }
}

private final class ContinuationResolver: @unchecked Sendable {
    private let lock = NSLock()
    private var hasResumed = false
    private let continuation: CheckedContinuation<SpeechRecognitionResult, Error>

    init(continuation: CheckedContinuation<SpeechRecognitionResult, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<SpeechRecognitionResult, Error>) {
        lock.lock()
        guard !hasResumed else {
            lock.unlock()
            return
        }
        hasResumed = true
        lock.unlock()
        continuation.resume(with: result)
    }
}
