import Foundation
import Observation

@MainActor
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
    private let subscriptionTier: AppState.SubscriptionTier

    private static let asrConfidenceThreshold: Double = 0.7
    private static let pronunciationSimilarityThreshold: Double = 0.82
    private static let pronunciationHighConfidenceThreshold: Double = 0.88

    // MARK: - Init

    init(
        claudeService: ClaudeServiceProtocol,
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol,
        subscriptionTier: AppState.SubscriptionTier = .core
    ) {
        self.claudeService = claudeService
        self.audioService = audioService
        self.speechRecognition = speechRecognition
        self.subscriptionTier = subscriptionTier
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

            if shouldAcceptAsCorrect(transcript: asrResult.transcript, confidence: asrResult.confidence) {
                feedback = PronunciationFeedback(
                    isCorrect: true,
                    feedback: "Your pronunciation sounds correct. The ASR and similarity checks both looked strong.",
                    articulatoryTip: nil,
                    similarSounds: []
                )
                phase = .showingFeedback
            } else {
                do {
                    try await claudeService.checkTierAllowed(tier: subscriptionTier)
                } catch {
                    phase = .error(claudeErrorMessage(for: error))
                    return
                }

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

    // MARK: - Heuristics

    private func shouldAcceptAsCorrect(transcript: String, confidence: Double) -> Bool {
        guard !targetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        let similarity = pronunciationSimilarity(transcript: transcript, target: targetText)

        if confidence >= Self.pronunciationHighConfidenceThreshold && similarity >= 0.72 {
            return true
        }

        if similarity >= Self.pronunciationSimilarityThreshold && confidence >= Self.asrConfidenceThreshold {
            return true
        }

        return false
    }

    private func pronunciationSimilarity(transcript: String, target: String) -> Double {
        let normalizedTranscript = normalizeForComparison(transcript)
        let normalizedTarget = normalizeForComparison(target)

        guard !normalizedTranscript.isEmpty, !normalizedTarget.isEmpty else { return 0 }

        let characterSimilarity = normalizedTranscript == normalizedTarget ? 1.0 : normalizedEditSimilarity(normalizedTranscript, normalizedTarget)
        let tokenSimilarity = tokenOverlapSimilarity(transcript, target)
        let lengthSimilarity = lengthSimilarityScore(normalizedTranscript, normalizedTarget)

        return (characterSimilarity * 0.5) + (tokenSimilarity * 0.3) + (lengthSimilarity * 0.2)
    }

    private func normalizeForComparison(_ text: String) -> String {
        let lowercased = text.lowercased()
        let filtered = lowercased.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }

    private func tokenOverlapSimilarity(_ left: String, _ right: String) -> Double {
        let leftTokens = Set(normalizedTokens(from: left))
        let rightTokens = Set(normalizedTokens(from: right))
        guard !leftTokens.isEmpty || !rightTokens.isEmpty else { return 0 }

        let intersection = leftTokens.intersection(rightTokens).count
        let union = leftTokens.union(rightTokens).count
        return union > 0 ? Double(intersection) / Double(union) : 0
    }

    private func normalizedTokens(from text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func lengthSimilarityScore(_ left: String, _ right: String) -> Double {
        let maxLength = max(left.count, right.count)
        guard maxLength > 0 else { return 0 }
        return 1.0 - (Double(abs(left.count - right.count)) / Double(maxLength))
    }

    private func normalizedEditSimilarity(_ left: String, _ right: String) -> Double {
        let leftChars = Array(left)
        let rightChars = Array(right)
        guard !leftChars.isEmpty, !rightChars.isEmpty else { return 0 }

        var previous = Array(0...rightChars.count)
        var current = Array(repeating: 0, count: rightChars.count + 1)

        for (i, leftChar) in leftChars.enumerated() {
            current[0] = i + 1
            for (j, rightChar) in rightChars.enumerated() {
                if leftChar == rightChar {
                    current[j + 1] = previous[j]
                } else {
                    current[j + 1] = min(previous[j], min(previous[j + 1], current[j])) + 1
                }
            }
            swap(&previous, &current)
        }

        let distance = previous[rightChars.count]
        let maxLength = max(leftChars.count, rightChars.count)
        return maxLength > 0 ? max(0, 1.0 - (Double(distance) / Double(maxLength))) : 0
    }

    private func claudeErrorMessage(for error: Error) -> String {
        if case ClaudeServiceError.tierLimitReached = error {
            return "Daily interaction limit reached for your subscription tier. Upgrade to continue."
        }
        return error.localizedDescription
    }
}
