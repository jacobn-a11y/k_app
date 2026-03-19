import Testing
import Foundation
@testable import HallyuCore

@Suite("HangulLessonViewModel Tests")
struct HangulLessonViewModelTests {

    private func makeViewModel(groupIndex: Int = 0) -> HangulLessonViewModel {
        HangulLessonViewModel(
            groupIndex: groupIndex,
            claudeService: MockClaudeService(),
            speechService: MockSpeechRecognitionService(),
            audioService: MockAudioService()
        )
    }

    // MARK: - Initialization

    @Test("ViewModel initializes with correct group")
    func initCorrectGroup() {
        let vm = makeViewModel(groupIndex: 0)
        #expect(vm.group.id == 0)
        #expect(vm.group.name == "First Sounds")
        #expect(!vm.jamoEntries.isEmpty)
    }

    @Test("ViewModel starts at first jamo, first step")
    func initStartState() {
        let vm = makeViewModel()
        #expect(vm.currentJamoIndex == 0)
        #expect(vm.currentStep == .strokeAnimation)
        #expect(vm.isLessonComplete == false)
    }

    @Test("Invalid group index results in empty lesson")
    func invalidGroupIndex() {
        let vm = makeViewModel(groupIndex: 99)
        #expect(vm.jamoEntries.isEmpty)
    }

    // MARK: - Step Advancement

    @Test("advanceStep moves through lesson steps")
    func advanceSteps() {
        let vm = makeViewModel()
        #expect(vm.currentStep == .strokeAnimation)

        vm.advanceStep()
        #expect(vm.currentStep == .listenPronunciation)

        vm.advanceStep()
        #expect(vm.currentStep == .mnemonicHint)

        vm.advanceStep()
        #expect(vm.currentStep == .tracePractice)

        vm.advanceStep()
        #expect(vm.currentStep == .speakPractice)
    }

    @Test("After last step, advances to next jamo")
    func advanceToNextJamo() {
        let vm = makeViewModel()
        let initialJamoIndex = vm.currentJamoIndex

        // Advance through all steps
        for _ in HangulLessonViewModel.JamoLessonStep.allCases {
            vm.advanceStep()
        }

        // Should have moved to next jamo (or skipped coaching)
        #expect(vm.currentJamoIndex > initialJamoIndex || vm.isLessonComplete)
    }

    @Test("Lesson completes after all jamo are done")
    func lessonCompletion() {
        let vm = makeViewModel()
        let jamoCount = vm.jamoEntries.count
        let stepsPerJamo = HangulLessonViewModel.JamoLessonStep.allCases.count

        // Advance through everything (with extra buffer for Claude coaching skip)
        for _ in 0..<(jamoCount * stepsPerJamo + jamoCount) {
            if vm.isLessonComplete { break }
            vm.advanceStep()
        }

        if vm.isSpotInTheWildActive {
            vm.completeSpotInTheWild(with: 0.9)
        }

        #expect(vm.isLessonComplete == true)
    }

    @Test("Completing final jamo activates spot-in-the-wild when task exists")
    func activatesSpotInTheWildAtLessonEnd() {
        let vm = makeViewModel(groupIndex: 0)
        let jamoCount = vm.jamoEntries.count
        let stepsPerJamo = HangulLessonViewModel.JamoLessonStep.allCases.count

        for _ in 0..<(jamoCount * stepsPerJamo + jamoCount) {
            if vm.isLessonComplete || vm.isSpotInTheWildActive { break }
            vm.advanceStep()
        }

        #expect(vm.isSpotInTheWildActive == true)
        #expect(vm.spotInTheWildTask != nil)
        #expect(vm.isLessonComplete == false)

        vm.completeSpotInTheWild(with: 0.8)
        #expect(vm.isLessonComplete == true)
        #expect(vm.spotInTheWildScore == 0.8)
    }

    // MARK: - Progress

    @Test("Progress starts at 0")
    func progressStartsAtZero() {
        let vm = makeViewModel()
        #expect(vm.progress >= 0)
        #expect(vm.progress < 0.1)
    }

    @Test("Progress increases with step advancement")
    func progressIncreases() {
        let vm = makeViewModel()
        let initial = vm.progress
        vm.advanceStep()
        #expect(vm.progress > initial)
    }

    // MARK: - Scoring

    @Test("recordTraceScore stores score for current jamo")
    func recordTraceScore() {
        let vm = makeViewModel()
        guard let jamo = vm.currentJamo else {
            Issue.record("No current jamo")
            return
        }

        vm.recordTraceScore(0.85)
        #expect(vm.scores[jamo.id]?.traceAccuracy == 0.85)
        #expect(vm.scores[jamo.id]?.attempts == 1)
    }

    @Test("Multiple trace scores update attempts count")
    func multipleTraceScores() {
        let vm = makeViewModel()
        vm.recordTraceScore(0.5)
        vm.recordTraceScore(0.8)
        guard let jamo = vm.currentJamo else { return }
        #expect(vm.scores[jamo.id]?.attempts == 2)
        #expect(vm.scores[jamo.id]?.traceAccuracy == 0.8) // latest score
    }

    // MARK: - Review Item Creation

    @Test("createReviewItems generates items for all jamo in lesson")
    func createReviewItems() {
        let vm = makeViewModel()
        let userId = UUID()
        let items = vm.createReviewItems(userId: userId)
        #expect(items.count == vm.jamoEntries.count)
        for item in items {
            #expect(item.userId == userId)
            #expect(item.itemType == "hangul")
        }
    }

    @Test("Review items have future next review date")
    func reviewItemsFutureDated() {
        let vm = makeViewModel()
        let items = vm.createReviewItems(userId: UUID())
        let now = Date()
        for item in items {
            #expect(item.nextReviewAt > now)
        }
    }

    // MARK: - Jamo Step Ordering

    @Test("JamoLessonStep has correct ordering")
    func stepOrdering() {
        #expect(HangulLessonViewModel.JamoLessonStep.strokeAnimation < .listenPronunciation)
        #expect(HangulLessonViewModel.JamoLessonStep.listenPronunciation < .mnemonicHint)
        #expect(HangulLessonViewModel.JamoLessonStep.mnemonicHint < .tracePractice)
        #expect(HangulLessonViewModel.JamoLessonStep.tracePractice < .speakPractice)
        #expect(HangulLessonViewModel.JamoLessonStep.speakPractice < .claudeCoaching)
    }

    @Test("Each step has a title")
    func stepTitles() {
        for step in HangulLessonViewModel.JamoLessonStep.allCases {
            #expect(!step.title.isEmpty)
        }
    }
}
