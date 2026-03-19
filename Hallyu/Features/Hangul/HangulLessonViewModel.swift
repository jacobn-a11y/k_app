import Foundation
import Observation

@MainActor
@Observable
final class HangulLessonViewModel {
    // MARK: - State

    private(set) var currentGroupIndex: Int
    private(set) var currentJamoIndex: Int = 0
    private(set) var currentStep: JamoLessonStep = .strokeAnimation
    private(set) var isLessonComplete: Bool = false
    private(set) var scores: [String: JamoScore] = [:]
    private(set) var overallScore: Double = 0

    let group: LessonGroup
    let jamoEntries: [JamoEntry]

    private let claudeService: ClaudeServiceProtocol
    private let speechService: SpeechRecognitionServiceProtocol
    private let audioService: AudioServiceProtocol

    // Pronunciation state
    var pronunciationFeedback: PronunciationFeedback?
    var pronunciationScore: PronunciationScore?
    var isRecording: Bool = false
    var recognitionResult: SpeechRecognitionResult?
    var traceScore: Double?

    // MARK: - Types

    enum JamoLessonStep: Int, CaseIterable, Comparable {
        case strokeAnimation = 0
        case listenPronunciation = 1
        case mnemonicHint = 2
        case tracePractice = 3
        case speakPractice = 4
        case claudeCoaching = 5

        static func < (lhs: JamoLessonStep, rhs: JamoLessonStep) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var title: String {
            switch self {
            case .strokeAnimation: return "Watch"
            case .listenPronunciation: return "Listen"
            case .mnemonicHint: return "Remember"
            case .tracePractice: return "Trace"
            case .speakPractice: return "Speak"
            case .claudeCoaching: return "Coach"
            }
        }
    }

    struct JamoScore: Equatable {
        let jamoId: String
        var traceAccuracy: Double
        var pronunciationAccuracy: Double
        var attempts: Int

        var combined: Double {
            (traceAccuracy + pronunciationAccuracy) / 2.0
        }
    }

    // MARK: - Computed Properties

    var currentJamo: JamoEntry? {
        guard currentJamoIndex < jamoEntries.count else { return nil }
        return jamoEntries[currentJamoIndex]
    }

    var progress: Double {
        guard !jamoEntries.isEmpty else { return 0 }
        let jamoProgress = Double(currentJamoIndex) / Double(jamoEntries.count)
        let stepProgress = Double(currentStep.rawValue) / Double(JamoLessonStep.allCases.count)
        let perJamo = 1.0 / Double(jamoEntries.count)
        return jamoProgress + stepProgress * perJamo
    }

    var totalJamoCount: Int { jamoEntries.count }
    var completedJamoCount: Int { currentJamoIndex }

    // MARK: - Init

    init(
        groupIndex: Int,
        claudeService: ClaudeServiceProtocol,
        speechService: SpeechRecognitionServiceProtocol,
        audioService: AudioServiceProtocol
    ) {
        self.currentGroupIndex = groupIndex
        self.claudeService = claudeService
        self.speechService = speechService
        self.audioService = audioService

        guard groupIndex < HangulData.lessonGroups.count else {
            self.group = LessonGroup(id: 0, name: "Empty", description: "", jamoIds: [])
            self.jamoEntries = []
            return
        }

        self.group = HangulData.lessonGroups[groupIndex]
        self.jamoEntries = group.jamoIds.compactMap { HangulData.jamo(for: $0) }
    }

    // MARK: - Actions

    func advanceStep() {
        guard let jamo = currentJamo else { return }

        let allSteps = JamoLessonStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return }

        let nextIndex = allSteps.index(after: currentIndex)

        if nextIndex < allSteps.endIndex {
            // Skip Claude coaching if pronunciation was good
            let nextStep = allSteps[nextIndex]
            if nextStep == .claudeCoaching {
                let shouldSkipCoaching = pronunciationScore.map { $0.overall >= 0.78 } ?? true
                if shouldSkipCoaching {
                    finishCurrentJamo(jamo: jamo)
                    return
                }
            }
            currentStep = nextStep
        } else {
            finishCurrentJamo(jamo: jamo)
        }
    }

    func recordTraceScore(_ score: Double) {
        guard let jamo = currentJamo else { return }
        traceScore = score

        var jamoScore = scores[jamo.id] ?? JamoScore(jamoId: jamo.id, traceAccuracy: 0, pronunciationAccuracy: 0, attempts: 0)
        jamoScore.traceAccuracy = score
        jamoScore.attempts += 1
        scores[jamo.id] = jamoScore
    }

    func startRecording() async throws {
        isRecording = true
        _ = try await audioService.startRecording()
    }

    func stopRecordingAndRecognize() async throws {
        let audioURL = try await audioService.stopRecording()
        isRecording = false

        let result = try await speechService.recognizeSpeech(from: audioURL)
        recognitionResult = result

        guard let jamo = currentJamo else { return }
        let score = PronunciationScorer.evaluate(
            transcript: result.transcript,
            target: String(jamo.character),
            asrConfidence: result.confidence
        )
        pronunciationScore = score

        var jamoScore = scores[jamo.id] ?? JamoScore(jamoId: jamo.id, traceAccuracy: 0, pronunciationAccuracy: 0, attempts: 0)
        jamoScore.pronunciationAccuracy = score.overall
        jamoScore.attempts += 1
        scores[jamo.id] = jamoScore

        // If pronunciation remains weak, get Claude coaching.
        if score.overall < 0.78 || score.jamoAccuracy < 0.72 {
            let feedback = try await claudeService.getPronunciationFeedback(
                transcript: result.transcript,
                target: String(jamo.character)
            )
            pronunciationFeedback = feedback
        }
    }

    func playPronunciation() async throws {
        guard let jamo = currentJamo else { return }
        guard let path = Bundle.main.path(forResource: jamo.audioFileRef, ofType: "m4a") else {
            print("[HangulLesson] Audio file not found: \(jamo.audioFileRef)")
            return
        }
        let audioURL = URL(fileURLWithPath: path)
        try await audioService.playAudio(url: audioURL)
    }

    // MARK: - Private

    private func finishCurrentJamo(jamo: JamoEntry) {
        pronunciationFeedback = nil
        pronunciationScore = nil
        recognitionResult = nil
        traceScore = nil

        if currentJamoIndex + 1 < jamoEntries.count {
            currentJamoIndex += 1
            currentStep = .strokeAnimation
        } else {
            isLessonComplete = true
            calculateOverallScore()
        }
    }

    private func calculateOverallScore() {
        guard !scores.isEmpty else {
            overallScore = 0
            return
        }
        overallScore = scores.values.reduce(0.0) { $0 + $1.combined } / Double(scores.count)
    }

    /// Create ReviewItems for completed jamo. Returns items ready for SRS insertion.
    func createReviewItems(userId: UUID) -> [ReviewItem] {
        let completedIds = jamoEntries.map(\.id)
        return HangulReviewIntegration.createReviewItems(
            userId: userId,
            completedJamoIds: completedIds,
            mode: .recognition
        )
    }
}
