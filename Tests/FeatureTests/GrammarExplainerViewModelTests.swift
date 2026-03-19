import Testing
import Foundation
@testable import HallyuCore

@Suite("GrammarExplainerViewModel Tests")
struct GrammarExplainerViewModelTests {

    private func makeViewModel() -> GrammarExplainerViewModel {
        GrammarExplainerViewModel(
            claudeService: MockClaudeService(),
            learnerModel: MockLearnerModelService()
        )
    }

    @Test("Initial state is idle")
    func initialState() {
        let vm = makeViewModel()
        #expect(vm.phase == .idle)
        #expect(vm.pattern == "")
        #expect(vm.explanation == nil)
        #expect(!vm.isActive)
    }

    @Test("Present grammar sets retrieval-first phase")
    func presentGrammar() {
        let vm = makeViewModel()
        vm.presentGrammar(pattern: "-이/가", mediaContext: "나는 학생이에요")
        #expect(vm.phase == .retrievalFirst)
        #expect(vm.pattern == "-이/가")
        #expect(vm.mediaContext == "나는 학생이에요")
        #expect(vm.isActive)
    }

    @Test("Submit answer records learner answer")
    func submitAnswer() {
        let vm = makeViewModel()
        vm.presentGrammar(pattern: "-이/가", mediaContext: "나는 학생이에요")
        vm.submitAnswer("Subject marker")
        #expect(vm.learnerAnswer == "Subject marker")
    }

    @Test("Request explanation transitions to showing")
    func requestExplanation() async {
        let vm = makeViewModel()
        vm.presentGrammar(pattern: "-이/가", mediaContext: "나는 학생이에요")
        await vm.requestExplanation()
        #expect(vm.phase == .showingExplanation)
        #expect(vm.explanation != nil)
        #expect(vm.hasExplanation)
    }

    @Test("Explanation includes all fields")
    func explanationFields() async {
        let vm = makeViewModel()
        vm.presentGrammar(pattern: "-이/가", mediaContext: "나는 학생이에요")
        await vm.requestExplanation()
        guard let explanation = vm.explanation else {
            Issue.record("Expected explanation")
            return
        }
        #expect(!explanation.ruleStatement.isEmpty)
        #expect(!explanation.explanation.isEmpty)
        #expect(!explanation.contrastiveExample.isEmpty)
        #expect(!explanation.retrievalQuestion.isEmpty)
    }

    @Test("Track grammar pattern succeeds")
    func trackPattern() async {
        let vm = makeViewModel()
        vm.presentGrammar(pattern: "-이/가", mediaContext: "나는 학생이에요")
        await vm.requestExplanation()
        await vm.trackGrammarPattern(userId: UUID())
        // No error thrown
    }

    @Test("Dismiss resets state")
    func dismiss() async {
        let vm = makeViewModel()
        vm.presentGrammar(pattern: "-이/가", mediaContext: "나는 학생이에요")
        await vm.requestExplanation()
        vm.dismiss()
        #expect(vm.phase == .idle)
        #expect(vm.pattern == "")
        #expect(vm.explanation == nil)
        #expect(!vm.isActive)
    }
}
