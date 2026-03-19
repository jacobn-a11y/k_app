import Testing
import Foundation
@testable import HallyuCore

@Suite("PlacementTestViewModel Tests")
struct PlacementTestViewModelTests {

    // MARK: - Initial State

    @Test("ViewModel starts with items loaded")
    func initialState() {
        let vm = PlacementTestViewModel()
        #expect(vm.currentItemIndex == 0)
        #expect(vm.totalItems > 0)
        #expect(vm.isComplete == false)
        #expect(vm.currentItem != nil)
        #expect(vm.results.isEmpty)
        #expect(vm.selectedOptionIndex == nil)
    }

    @Test("Item pool has items for all CEFR levels")
    func itemPoolCoverage() {
        let levels = Set(PlacementTestViewModel.itemPool.map { $0.cefrLevel })
        #expect(levels.contains("A1"))
        #expect(levels.contains("A2"))
        #expect(levels.contains("B1"))
        #expect(levels.contains("B2"))
    }

    @Test("Item pool has multiple item types")
    func itemTypesCoverage() {
        let types = Set(PlacementTestViewModel.itemPool.map { $0.type })
        #expect(types.contains(.hangulReading))
        #expect(types.contains(.vocabularyRecognition))
        #expect(types.contains(.grammarMultipleChoice))
        #expect(types.contains(.listeningComprehension))
    }

    // MARK: - Answering Questions

    @Test("Submitting correct answer records result")
    func submitCorrectAnswer() {
        let vm = PlacementTestViewModel()
        guard let item = vm.currentItem else {
            Issue.record("Should have a current item")
            return
        }
        vm.submitAnswer(optionIndex: item.correctIndex)
        #expect(vm.results.count == 1)
        #expect(vm.results.first?.wasCorrect == true)
        #expect(vm.currentItemIndex == 1)
    }

    @Test("Submitting wrong answer records incorrect result")
    func submitWrongAnswer() {
        let vm = PlacementTestViewModel()
        guard let item = vm.currentItem else {
            Issue.record("Should have a current item")
            return
        }
        let wrongIndex = (item.correctIndex + 1) % item.options.count
        vm.submitAnswer(optionIndex: wrongIndex)
        #expect(vm.results.count == 1)
        #expect(vm.results.first?.wasCorrect == false)
    }

    @Test("Skip records incorrect result with -1 index")
    func skipItem() {
        let vm = PlacementTestViewModel()
        vm.skipItem()
        #expect(vm.results.count == 1)
        #expect(vm.results.first?.wasCorrect == false)
        #expect(vm.results.first?.selectedIndex == -1)
    }

    @Test("Index advances after each answer")
    func indexAdvances() {
        let vm = PlacementTestViewModel()
        vm.submitAnswer(optionIndex: 0)
        #expect(vm.currentItemIndex == 1)
        vm.submitAnswer(optionIndex: 0)
        #expect(vm.currentItemIndex == 2)
    }

    @Test("selectedOptionIndex resets after submit")
    func selectedOptionResets() {
        let vm = PlacementTestViewModel()
        vm.selectedOptionIndex = 2
        vm.submitAnswer(optionIndex: 2)
        #expect(vm.selectedOptionIndex == nil)
    }

    // MARK: - Completion

    @Test("Test completes after all items answered")
    func completesAfterAllItems() {
        let vm = PlacementTestViewModel()
        let total = vm.totalItems
        for _ in 0..<total {
            vm.submitAnswer(optionIndex: 0)
        }
        #expect(vm.isComplete == true)
        #expect(vm.results.count == total)
    }

    @Test("Estimated level is pre-A1 when all wrong")
    func allWrongGivesPreA1() {
        let vm = PlacementTestViewModel()
        for _ in 0..<vm.totalItems {
            guard let item = vm.currentItem else { break }
            let wrongIndex = (item.correctIndex + 1) % item.options.count
            vm.submitAnswer(optionIndex: wrongIndex)
        }
        #expect(vm.isComplete == true)
        #expect(vm.estimatedLevel == "pre-A1")
    }

    @Test("Estimated level is higher when all correct")
    func allCorrectGivesHigherLevel() {
        let vm = PlacementTestViewModel()
        for _ in 0..<vm.totalItems {
            guard let item = vm.currentItem else { break }
            vm.submitAnswer(optionIndex: item.correctIndex)
        }
        #expect(vm.isComplete == true)
        let validLevels = ["A1", "A2", "B1", "B2"]
        #expect(validLevels.contains(vm.estimatedLevel))
    }

    @Test("Skill breakdown is populated after completion")
    func skillBreakdownPopulated() {
        let vm = PlacementTestViewModel()
        for _ in 0..<vm.totalItems {
            vm.submitAnswer(optionIndex: 0)
        }
        #expect(!vm.skillBreakdown.isEmpty)
    }

    // MARK: - Progress

    @Test("Progress fraction increases as items are answered")
    func progressFraction() {
        let vm = PlacementTestViewModel()
        let initial = vm.progressFraction
        #expect(initial == 0)
        vm.submitAnswer(optionIndex: 0)
        #expect(vm.progressFraction > initial)
    }

    @Test("Correct count tracks correct answers only")
    func correctCount() {
        let vm = PlacementTestViewModel()
        guard let item = vm.currentItem else { return }
        vm.submitAnswer(optionIndex: item.correctIndex) // correct
        vm.skipItem() // wrong
        #expect(vm.correctCount == 1)
        #expect(vm.totalAnswered == 2)
    }

    @Test("Selected test set includes listening items")
    func selectedSetIncludesListening() {
        let vm = PlacementTestViewModel()
        var seenTypes: Set<PlacementTestViewModel.ItemType> = []

        while let item = vm.currentItem {
            seenTypes.insert(item.type)
            vm.submitAnswer(optionIndex: item.correctIndex)
        }

        #expect(seenTypes.contains(.listeningComprehension))
    }

    @Test("Correct response nudges difficulty upward")
    func correctResponseRaisesDifficulty() {
        let vm = PlacementTestViewModel()
        guard let item = vm.currentItem else {
            Issue.record("Should have a current item")
            return
        }

        let currentRank = levelRank(item.cefrLevel)
        vm.submitAnswer(optionIndex: item.correctIndex)
        guard let nextItem = vm.currentItem else {
            Issue.record("Should have a next item")
            return
        }

        #expect(levelRank(nextItem.cefrLevel) >= currentRank)
    }

    @Test("Wrong response nudges difficulty downward")
    func wrongResponseLowersDifficulty() {
        let vm = PlacementTestViewModel()
        guard let item = vm.currentItem else {
            Issue.record("Should have a current item")
            return
        }

        let currentRank = levelRank(item.cefrLevel)
        let wrongIndex = (item.correctIndex + 1) % item.options.count
        vm.submitAnswer(optionIndex: wrongIndex)
        guard let nextItem = vm.currentItem else {
            Issue.record("Should have a next item")
            return
        }

        #expect(levelRank(nextItem.cefrLevel) <= currentRank)
    }

    // MARK: - Item Validity

    @Test("All items have valid correct indices")
    func validCorrectIndices() {
        for item in PlacementTestViewModel.itemPool {
            #expect(item.correctIndex >= 0 && item.correctIndex < item.options.count,
                    "Item '\(item.prompt)' has invalid correctIndex \(item.correctIndex)")
        }
    }

    @Test("All items have at least 2 options")
    func minimumOptions() {
        for item in PlacementTestViewModel.itemPool {
            #expect(item.options.count >= 2,
                    "Item '\(item.prompt)' has fewer than 2 options")
        }
    }

    @Test("Response time is recorded")
    func responseTimeRecorded() {
        let vm = PlacementTestViewModel()
        vm.submitAnswer(optionIndex: 0)
        #expect(vm.results.first?.responseTimeMs != nil)
        #expect(vm.results.first!.responseTimeMs >= 0)
    }

    private func levelRank(_ level: String) -> Int {
        switch level {
        case "pre-A1": return 0
        case "A1": return 1
        case "A2": return 2
        case "B1": return 3
        case "B2": return 4
        default: return 1
        }
    }
}
