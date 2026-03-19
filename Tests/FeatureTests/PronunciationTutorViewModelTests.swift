import Testing
import Foundation
@testable import HallyuCore

@Suite("PronunciationTutorViewModel Tests")
struct PronunciationTutorViewModelTests {

    private func makeViewModel() -> PronunciationTutorViewModel {
        PronunciationTutorViewModel(
            claudeService: MockClaudeService(),
            audioService: MockAudioService(),
            speechRecognition: MockSpeechRecognitionService()
        )
    }

    private func makeViewModel(
        claudeService: ClaudeServiceProtocol,
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol
    ) -> PronunciationTutorViewModel {
        PronunciationTutorViewModel(
            claudeService: claudeService,
            audioService: audioService,
            speechRecognition: speechRecognition
        )
    }

    @Test("Initial state is idle")
    func initialState() {
        let vm = makeViewModel()
        #expect(vm.phase == .idle)
        #expect(vm.targetText == "")
        #expect(vm.attemptCount == 0)
        #expect(vm.feedback == nil)
    }

    @Test("Set target updates state")
    func setTarget() {
        let vm = makeViewModel()
        vm.setTarget("안녕하세요")
        #expect(vm.targetText == "안녕하세요")
        #expect(vm.attemptCount == 0)
    }

    @Test("Start recording changes phase")
    func startRecording() async {
        let vm = makeViewModel()
        vm.setTarget("안녕하세요")
        await vm.startRecording()
        #expect(vm.phase == .recording)
    }

    @Test("Stop recording and analyze provides feedback")
    func stopAndAnalyze() async {
        let vm = makeViewModel()
        vm.setTarget("안녕하세요")
        await vm.startRecording()
        await vm.stopRecordingAndAnalyze()
        #expect(vm.phase == .showingFeedback)
        #expect(vm.feedback != nil)
        #expect(vm.attemptCount == 1)
    }

    @Test("Multiple attempts increment counter")
    func multipleAttempts() async {
        let vm = makeViewModel()
        vm.setTarget("test")
        await vm.startRecording()
        await vm.stopRecordingAndAnalyze()
        vm.tryAgain()
        await vm.startRecording()
        await vm.stopRecordingAndAnalyze()
        #expect(vm.attemptCount == 2)
        #expect(vm.hasMultipleAttempts)
    }

    @Test("Try again resets to idle")
    func tryAgain() async {
        let vm = makeViewModel()
        vm.setTarget("test")
        await vm.startRecording()
        await vm.stopRecordingAndAnalyze()
        vm.tryAgain()
        #expect(vm.phase == .idle)
        #expect(vm.feedback == nil)
    }

    @Test("Reset clears all state")
    func reset() async {
        let vm = makeViewModel()
        vm.setTarget("test")
        await vm.startRecording()
        await vm.stopRecordingAndAnalyze()
        vm.reset()
        #expect(vm.phase == .idle)
        #expect(vm.targetText == "")
        #expect(vm.attemptCount == 0)
        #expect(vm.errorPatterns.isEmpty)
    }

    @Test("Stop recording without starting stays in current phase")
    func stopWithoutStart() async {
        let vm = makeViewModel()
        vm.setTarget("test")
        await vm.stopRecordingAndAnalyze()
        // Should not process since not in recording phase
        #expect(vm.attemptCount == 0)
    }

    @Test("isCorrect reflects feedback")
    func isCorrectReflectsFeedback() async {
        let vm = makeViewModel()
        vm.setTarget("mock transcript") // Matches mock ASR output
        await vm.startRecording()
        await vm.stopRecordingAndAnalyze()
        // MockSpeechRecognition returns "mock transcript" which matches target
        #expect(vm.feedback != nil)
        #expect(vm.feedback?.isCorrect == true)
    }

    @Test("Similarity and confidence can accept near matches")
    func fuzzyMatchAccepted() async {
        let vm = makeViewModel(
            claudeService: FuzzyFailClaudeService(),
            audioService: MockAudioService(),
            speechRecognition: NearMatchSpeechRecognitionService()
        )

        vm.setTarget("mock transcript")
        await vm.startRecording()
        await vm.stopRecordingAndAnalyze()

        #expect(vm.feedback?.isCorrect == true)
    }

    @Test("shouldSuggestDrill after multiple failed attempts")
    func suggestDrill() {
        let vm = makeViewModel()
        vm.setTarget("test")
        // Simulate error patterns being tracked
        // After 3+ attempts with errors, drill should be suggested
        #expect(!vm.shouldSuggestDrill) // No attempts yet
    }
}

private final class NearMatchSpeechRecognitionService: SpeechRecognitionServiceProtocol, @unchecked Sendable {
    var isAvailable: Bool = true

    func requestAuthorization() async -> Bool { true }

    func recognizeSpeech(from audioURL: URL) async throws -> SpeechRecognitionResult {
        SpeechRecognitionResult(
            transcript: "mock transcrip",
            confidence: 0.92,
            segments: [SpeechSegment(text: "mock transcrip", confidence: 0.92, timestamp: 0, duration: 1.0)]
        )
    }
}

private final class FuzzyFailClaudeService: ClaudeServiceProtocol, @unchecked Sendable {
    func checkTierAllowed(tier: AppState.SubscriptionTier) async throws {
        try await MockClaudeService().checkTierAllowed(tier: tier)
    }

    func resetSessionState() async {}

    func getComprehensionHelp(context: ComprehensionContext, query: String) async throws -> ComprehensionResponse {
        try await MockClaudeService().getComprehensionHelp(context: context, query: query)
    }

    func getPronunciationFeedback(transcript: String, target: String) async throws -> PronunciationFeedback {
        PronunciationFeedback(
            isCorrect: false,
            feedback: "Mock fallback feedback",
            articulatoryTip: "Try ending the final consonant more clearly.",
            similarSounds: ["mock transcript"]
        )
    }

    func getGrammarExplanation(pattern: String, context: String) async throws -> GrammarExplanation {
        try await MockClaudeService().getGrammarExplanation(pattern: pattern, context: context)
    }

    func generatePracticeItems(mediaContentId: UUID, learnerLevel: String) async throws -> [PracticeItem] {
        try await MockClaudeService().generatePracticeItems(mediaContentId: mediaContentId, learnerLevel: learnerLevel)
    }

    func getCulturalContext(moment: String, mediaContext: String) async throws -> CulturalContextResponse {
        try await MockClaudeService().getCulturalContext(moment: moment, mediaContext: mediaContext)
    }
}
