import Testing
import Foundation
@testable import HallyuCore

@Suite("ComprehensionCoachViewModel Tests")
struct ComprehensionCoachViewModelTests {

    private func makeViewModel(
        tier: AppState.SubscriptionTier = .core
    ) -> ComprehensionCoachViewModel {
        ComprehensionCoachViewModel(
            claudeService: MockClaudeService(),
            learnerModel: MockLearnerModelService(),
            subscriptionTier: tier
        )
    }

    @Test("Initial state is idle")
    func initialState() {
        let vm = makeViewModel()
        #expect(vm.phase == .idle)
        #expect(vm.targetWord == "")
        #expect(vm.response == nil)
        #expect(!vm.isActive)
    }

    @Test("Word tap sets retrieval prompt phase")
    func wordTapSetsRetrievalPhase() {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        #expect(vm.phase == .retrievalPrompt)
        #expect(vm.targetWord == "안녕")
        #expect(vm.mediaTitle == "Drama")
        #expect(vm.isActive)
    }

    @Test("Submit guess records learner guess")
    func submitGuessRecords() {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        vm.submitGuess("hello")
        #expect(vm.learnerGuess == "hello")
    }

    @Test("Request explanation transitions to showingResult")
    func requestExplanation() async {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: ["네"]
        )
        await vm.requestExplanation(
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: ["네"]
        )
        #expect(vm.phase == .showingResult)
        #expect(vm.response != nil)
        #expect(vm.hasResponse)
    }

    @Test("Guess was close detection works")
    func guessWasClose() async {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        vm.submitGuess("mock literal meaning")
        await vm.requestExplanation(
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        #expect(vm.guessWasClose)
    }

    @Test("Guess not close with wrong answer")
    func guessNotClose() async {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        vm.submitGuess("completely wrong")
        await vm.requestExplanation(
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        #expect(!vm.guessWasClose)
    }

    @Test("Add to review marks as added")
    func addToReview() async {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        await vm.requestExplanation(
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        await vm.addToReview(userId: UUID())
        #expect(vm.addedToReview)
    }

    @Test("Dismiss resets state")
    func dismiss() async {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        await vm.requestExplanation(
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        vm.dismiss()
        #expect(vm.phase == .idle)
        #expect(vm.response == nil)
        #expect(vm.targetWord == "")
        #expect(!vm.isActive)
    }

    @Test("Empty guess still allows explanation request")
    func emptyGuessAllowed() async {
        let vm = makeViewModel()
        vm.onWordTapped(
            word: "안녕",
            mediaTitle: "Drama",
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        // Skip guess, go straight to explanation
        await vm.requestExplanation(
            transcript: "안녕하세요",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        #expect(vm.phase == .showingResult)
        #expect(vm.learnerGuess == "")
    }
}
