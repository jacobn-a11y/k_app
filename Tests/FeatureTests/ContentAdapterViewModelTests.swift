import Testing
import Foundation
@testable import HallyuCore

@Suite("ContentAdapterViewModel Tests")
struct ContentAdapterViewModelTests {

    private func makeViewModel() -> ContentAdapterViewModel {
        ContentAdapterViewModel(
            claudeService: MockClaudeService(),
            learnerModel: MockLearnerModelService()
        )
    }

    @Test("Initial state is idle")
    func initialState() {
        let vm = makeViewModel()
        #expect(vm.phase == .idle)
        #expect(vm.exercises.isEmpty)
        #expect(vm.currentExerciseIndex == 0)
    }

    @Test("Generate exercises transitions to showing")
    func generateExercises() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        #expect(vm.phase == .showingExercises)
        #expect(!vm.exercises.isEmpty)
        #expect(vm.totalExercises > 0)
    }

    @Test("Current exercise returns first item")
    func currentExercise() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        #expect(vm.currentExercise != nil)
        #expect(vm.currentExerciseIndex == 0)
    }

    @Test("Submit correct answer marks as correct")
    func submitCorrectAnswer() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        guard let exercise = vm.currentExercise else {
            Issue.record("Expected exercise")
            return
        }
        vm.submitAnswer(exercise.correctAnswer)
        #expect(vm.isShowingAnswer)
        #expect(vm.correctCount == 1)
    }

    @Test("Submit wrong answer marks as incorrect")
    func submitWrongAnswer() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        vm.submitAnswer("completely wrong")
        #expect(vm.isShowingAnswer)
        #expect(vm.correctCount == 0)
    }

    @Test("Next exercise advances index")
    func nextExercise() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        vm.submitAnswer("test")
        vm.nextExercise()
        // MockClaudeService returns 1 exercise, so we should be completed
        #expect(vm.phase == .completed)
    }

    @Test("Progress calculation")
    func progressCalculation() async {
        let vm = makeViewModel()
        #expect(vm.progress == 0) // No exercises
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        #expect(vm.progress == 0) // At index 0 of N
    }

    @Test("Accuracy calculation")
    func accuracyCalculation() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        guard let exercise = vm.currentExercise else { return }
        vm.submitAnswer(exercise.correctAnswer)
        #expect(vm.accuracy == 1.0)
    }

    @Test("Reset clears state")
    func reset() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        vm.reset()
        #expect(vm.phase == .idle)
        #expect(vm.exercises.isEmpty)
        #expect(vm.currentExerciseIndex == 0)
        #expect(vm.answers.isEmpty)
    }

    @Test("Update learner model after completion")
    func updateLearnerModel() async {
        let vm = makeViewModel()
        await vm.generateExercises(mediaContentId: UUID(), learnerLevel: "A1")
        vm.submitAnswer("test")
        await vm.updateLearnerModel(userId: UUID())
        // Should not throw
    }
}
