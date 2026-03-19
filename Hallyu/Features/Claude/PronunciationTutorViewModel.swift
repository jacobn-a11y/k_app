import Foundation
import Observation

@Observable
final class PronunciationTutorViewModel {

    // MARK: - State

    enum Phase: Equatable {
        case idle
        case recording
        case processing      // ASR + Claude
        case showingFeedback
        case showingDrill
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var targetText: String = ""
    private(set) var recognizedTranscript: String = ""
    private(set) var feedback: PronunciationFeedback?
    private(set) var attemptCount: Int = 0
    private(set) var errorPatterns: [String] = []

    let claudeService: ClaudeServiceProtocol
    let audioService: AudioServiceProtocol
    let speechRecognition: SpeechRecognitionServiceProtocol

    private static let asrConfidenceThreshold: Double = 0.7

    // MARK: - Init

    init(
        claudeService: ClaudeServiceProtocol,
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol
    ) {
        self.claudeService = claudeService
        self.audioService = audioService
        self.speechRecognition = speechRecognition
    }

    // MARK: - Actions

    func setTarget(_ text: String) {
        targetText = text
        attemptCount = 0
        feedback = nil
        errorPatterns = []
        phase = .idle
    }

    func startRecording() async {
        phase = .recording
        do {
            _ = try await audioService.startRecording()
        } catch {
            phase = .error("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecordingAndAnalyze() async {
        guard phase == .recording else { return }
        phase = .processing
        attemptCount += 1

        do {
            let audioURL = try await audioService.stopRecording()
            let asrResult = try await speechRecognition.recognizeSpeech(from: audioURL)
            recognizedTranscript = asrResult.transcript

            if asrResult.transcript.lowercased() == targetText.lowercased()
                && asrResult.confidence >= Self.asrConfidenceThreshold {
                // ASR match — success without Claude
                feedback = PronunciationFeedback(
                    isCorrect: true,
                    feedback: "Your pronunciation sounds correct!",
                    articulatoryTip: nil,
                    similarSounds: []
                )
                phase = .showingFeedback
            } else {
                // Below threshold — ask Claude for coaching
                let claudeFeedback = try await claudeService.getPronunciationFeedback(
                    transcript: asrResult.transcript,
                    target: targetText
                )
                feedback = claudeFeedback

                // Track error patterns for drill generation
                if !claudeFeedback.isCorrect, let tip = claudeFeedback.articulatoryTip {
                    if !errorPatterns.contains(tip) {
                        errorPatterns.append(tip)
                    }
                }

                phase = .showingFeedback
            }
        } catch {
            phase = .error("Analysis failed: \(error.localizedDescription)")
        }
    }

    func tryAgain() {
        feedback = nil
        phase = .idle
    }

    func reset() {
        phase = .idle
        targetText = ""
        recognizedTranscript = ""
        feedback = nil
        attemptCount = 0
        errorPatterns = []
    }

    // MARK: - Computed

    var isCorrect: Bool {
        feedback?.isCorrect ?? false
    }

    var hasMultipleAttempts: Bool {
        attemptCount > 1
    }

    var shouldSuggestDrill: Bool {
        attemptCount >= 3 && !errorPatterns.isEmpty
    }
}
