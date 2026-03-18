import Testing
import Foundation
@testable import HallyuCore

@Suite("SyllableBlockBuilder Tests")
struct SyllableBlockBuilderTests {

    private func makeViewModel(jamoIds: [String]? = nil) -> SyllableBlockBuilderViewModel {
        let ids = jamoIds ?? ["ㄱ", "ㄴ", "ㄷ", "ㅏ", "ㅓ", "ㅗ"]
        return SyllableBlockBuilderViewModel(learnedJamoIds: ids)
    }

    // MARK: - Initialization

    @Test("ViewModel separates consonants and vowels")
    func separatesConsonantsAndVowels() {
        let vm = makeViewModel()
        #expect(!vm.availableConsonants.isEmpty)
        #expect(!vm.availableVowels.isEmpty)
        for c in vm.availableConsonants {
            #expect(c.positionRules.contains(.initial) || c.positionRules.contains(.final_))
        }
        for v in vm.availableVowels {
            #expect(v.positionRules.contains(.medial))
        }
    }

    @Test("Empty learned jamo produces empty tile sets")
    func emptyLearned() {
        let vm = SyllableBlockBuilderViewModel(learnedJamoIds: [])
        #expect(vm.availableConsonants.isEmpty)
        #expect(vm.availableVowels.isEmpty)
    }

    // MARK: - Jamo Placement

    @Test("Place initial consonant")
    func placeInitial() {
        let vm = makeViewModel()
        let giyeok = HangulData.jamo(for: "ㄱ")!
        vm.placeJamo(giyeok, in: .initial)
        #expect(vm.initialSlot?.id == "ㄱ")
    }

    @Test("Place medial vowel")
    func placeMedial() {
        let vm = makeViewModel()
        let a = HangulData.jamo(for: "ㅏ")!
        vm.placeJamo(a, in: .medial)
        #expect(vm.medialSlot?.id == "ㅏ")
    }

    @Test("Place final consonant")
    func placeFinal() {
        let vm = makeViewModel()
        let nieun = HangulData.jamo(for: "ㄴ")!
        vm.placeJamo(nieun, in: .final_)
        #expect(vm.finalSlot?.id == "ㄴ")
    }

    @Test("Cannot place vowel in initial slot")
    func cannotPlaceVowelInInitial() {
        let vm = makeViewModel()
        let a = HangulData.jamo(for: "ㅏ")!
        vm.placeJamo(a, in: .initial)
        #expect(vm.initialSlot == nil)
    }

    @Test("Cannot place consonant in medial slot")
    func cannotPlaceConsonantInMedial() {
        let vm = makeViewModel()
        let giyeok = HangulData.jamo(for: "ㄱ")!
        vm.placeJamo(giyeok, in: .medial)
        #expect(vm.medialSlot == nil)
    }

    // MARK: - Composition

    @Test("Composing ㄱ + ㅏ produces 가")
    func composeGa() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄱ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        #expect(vm.composedCharacter == "가")
    }

    @Test("Composing ㄴ + ㅏ produces 나")
    func composeNa() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄴ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        #expect(vm.composedCharacter == "나")
    }

    @Test("Composing with final consonant works")
    func composeWithFinal() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄱ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        vm.placeJamo(HangulData.jamo(for: "ㄴ")!, in: .final_)
        #expect(vm.composedCharacter == "간")
    }

    @Test("Incomplete composition returns nil")
    func incompleteComposition() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄱ")!, in: .initial)
        #expect(vm.composedCharacter == nil)
    }

    // MARK: - Clear & Remove

    @Test("clearAll resets all slots")
    func clearAll() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄱ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        vm.clearAll()
        #expect(vm.initialSlot == nil)
        #expect(vm.medialSlot == nil)
        #expect(vm.finalSlot == nil)
        #expect(vm.composedCharacter == nil)
    }

    @Test("removeJamo clears specific slot")
    func removeJamo() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄱ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        vm.removeJamo(from: .medial)
        #expect(vm.medialSlot == nil)
        #expect(vm.composedCharacter == nil) // can't compose without vowel
        #expect(vm.initialSlot?.id == "ㄱ") // initial still set
    }

    // MARK: - Answer Checking

    @Test("Correct answer increments correct count")
    func correctAnswer() {
        let vm = makeViewModel()
        // Build 가
        vm.placeJamo(HangulData.jamo(for: "ㄱ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        vm.targetCharacter = "가"
        vm.checkAnswer()
        #expect(vm.isCorrect == true)
        #expect(vm.correctCount == 1)
        #expect(vm.attempts == 1)
    }

    @Test("Incorrect answer tracked")
    func incorrectAnswer() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄴ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        vm.targetCharacter = "가" // target is 가, built 나
        vm.checkAnswer()
        #expect(vm.isCorrect == false)
        #expect(vm.correctCount == 0)
        #expect(vm.attempts == 1)
    }

    @Test("Score is calculated correctly")
    func scoreCalculation() {
        let vm = makeViewModel()
        vm.placeJamo(HangulData.jamo(for: "ㄱ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        vm.targetCharacter = "가"
        vm.checkAnswer() // correct
        vm.clearAll()
        vm.placeJamo(HangulData.jamo(for: "ㄴ")!, in: .initial)
        vm.placeJamo(HangulData.jamo(for: "ㅏ")!, in: .medial)
        vm.targetCharacter = "가"
        vm.checkAnswer() // incorrect
        #expect(vm.score == 0.5)
    }

    // MARK: - Random Target

    @Test("generateRandomTarget produces a valid character")
    func randomTarget() {
        let vm = makeViewModel()
        vm.generateRandomTarget()
        #expect(vm.targetCharacter != nil)
        if let target = vm.targetCharacter {
            #expect(HangulUtilities.isHangulSyllable(target))
        }
    }
}
