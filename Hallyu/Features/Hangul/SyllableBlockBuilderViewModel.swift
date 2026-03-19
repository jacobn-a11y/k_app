import Foundation
import Observation

// MARK: - View Model

@Observable
final class SyllableBlockBuilderViewModel {
    // Slots
    var initialSlot: JamoEntry?
    var medialSlot: JamoEntry?
    var finalSlot: JamoEntry?

    // Available tiles (from learned jamo)
    let availableConsonants: [JamoEntry]
    let availableVowels: [JamoEntry]

    // State
    private(set) var composedCharacter: Character?
    private(set) var isCorrect: Bool?
    var targetCharacter: Character?
    private(set) var score: Double = 0
    private(set) var attempts: Int = 0
    private(set) var correctCount: Int = 0

    init(learnedJamoIds: [String]) {
        let learned = learnedJamoIds.compactMap { HangulData.jamo(for: $0) }
        availableConsonants = learned.filter { $0.positionRules.contains(.initial) || $0.positionRules.contains(.final_) }
        availableVowels = learned.filter { $0.positionRules.contains(.medial) }
    }

    func placeJamo(_ jamo: JamoEntry, in position: JamoPosition) {
        switch position {
        case .initial:
            if jamo.positionRules.contains(.initial) {
                initialSlot = jamo
            }
        case .medial:
            if jamo.positionRules.contains(.medial) {
                medialSlot = jamo
            }
        case .final_:
            if jamo.positionRules.contains(.final_) {
                finalSlot = jamo
            }
        }
        updateComposition()
    }

    func removeJamo(from position: JamoPosition) {
        switch position {
        case .initial: initialSlot = nil
        case .medial: medialSlot = nil
        case .final_: finalSlot = nil
        }
        updateComposition()
    }

    func clearAll() {
        initialSlot = nil
        medialSlot = nil
        finalSlot = nil
        composedCharacter = nil
        isCorrect = nil
    }

    func checkAnswer() {
        guard let target = targetCharacter, let composed = composedCharacter else {
            isCorrect = false
            return
        }
        attempts += 1
        isCorrect = composed == target
        if isCorrect == true {
            correctCount += 1
        }
        score = attempts > 0 ? Double(correctCount) / Double(attempts) : 0
    }

    func generateRandomTarget() {
        guard !availableConsonants.isEmpty, !availableVowels.isEmpty else { return }

        let initialConsonants = availableConsonants.filter { $0.positionRules.contains(.initial) }
        guard let initial = initialConsonants.randomElement(),
              let vowel = availableVowels.randomElement() else { return }

        let leadIndex = HangulUtilities.leadingConsonants.firstIndex(of: initial.character) ?? 0
        let vowelIndex = HangulUtilities.medialVowels.firstIndex(of: vowel.character) ?? 0

        // 50% chance of adding a final consonant
        let tailIndex: Int
        if Bool.random() {
            let finalConsonants = availableConsonants.filter { $0.positionRules.contains(.final_) }
            if let final_ = finalConsonants.randomElement(),
               let idx = HangulUtilities.finalConsonants.firstIndex(where: { $0 == final_.character }) {
                tailIndex = idx
            } else {
                tailIndex = 0
            }
        } else {
            tailIndex = 0
        }

        targetCharacter = HangulUtilities.composeSyllable(
            leadIndex: leadIndex,
            vowelIndex: vowelIndex,
            tailIndex: tailIndex
        )
    }

    // MARK: - Private

    private func updateComposition() {
        guard let initial = initialSlot, let medial = medialSlot else {
            composedCharacter = nil
            return
        }

        let leadIndex = HangulUtilities.leadingConsonants.firstIndex(of: initial.character) ?? 0
        let vowelIndex = HangulUtilities.medialVowels.firstIndex(of: medial.character) ?? 0

        let tailIndex: Int
        if let final_ = finalSlot {
            // ?? 0 is intentional: index 0 in finalConsonants represents "no final consonant" (empty),
            // so falling back to 0 when a character isn't found is the correct default behavior.
            tailIndex = HangulUtilities.finalConsonants.firstIndex(where: { $0 == final_.character }) ?? 0
        } else {
            tailIndex = 0
        }

        composedCharacter = HangulUtilities.composeSyllable(
            leadIndex: leadIndex,
            vowelIndex: vowelIndex,
            tailIndex: tailIndex
        )
    }
}
