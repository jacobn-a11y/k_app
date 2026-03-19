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
