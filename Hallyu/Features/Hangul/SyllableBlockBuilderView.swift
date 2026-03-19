import SwiftUI

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

// MARK: - View

struct SyllableBlockBuilderView: View {
    @State private var viewModel: SyllableBlockBuilderViewModel
    @State private var draggedJamo: JamoEntry?

    init(learnedJamoIds: [String]) {
        _viewModel = State(initialValue: SyllableBlockBuilderViewModel(learnedJamoIds: learnedJamoIds))
    }

    var body: some View {
        VStack(spacing: 24) {
            // Target
            if let target = viewModel.targetCharacter {
                VStack(spacing: 4) {
                    Text("Build this character:")
                        .font(.headline)
                    Text(String(target))
                        .font(.system(size: 60, weight: .bold))
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Target character \(String(target))")
                        .accessibilityHint("Build this syllable using the tiles below.")
                }
            }

            // Composed result
            composedDisplay

            // Slots
            HStack(spacing: 16) {
                slotView(position: .initial, jamo: viewModel.initialSlot, label: "Initial")
                slotView(position: .medial, jamo: viewModel.medialSlot, label: "Vowel")
                slotView(position: .final_, jamo: viewModel.finalSlot, label: "Final")
            }

            // Available tiles
            VStack(spacing: 8) {
                Text("Consonants")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(viewModel.availableConsonants, id: \.id) { jamo in
                        jamoTile(jamo)
                    }
                }

                Text("Vowels")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(viewModel.availableVowels, id: \.id) { jamo in
                        jamoTile(jamo)
                    }
                }
            }
            .padding(.horizontal)

            // Actions
            HStack(spacing: 16) {
                Button("Clear") {
                    viewModel.clearAll()
                }
                .buttonStyle(.bordered)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Clear syllable")
                .accessibilityHint("Removes all jamo from the slots.")

                Button("Check") {
                    viewModel.checkAnswer()
                    if let isCorrect = viewModel.isCorrect {
                        HapticManager.play(isCorrect ? .success : .error)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.composedCharacter == nil)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Check answer")
                .accessibilityHint("Checks whether the composed syllable matches the target.")

                Button("New") {
                    viewModel.clearAll()
                    viewModel.generateRandomTarget()
                }
                .buttonStyle(.bordered)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("New syllable")
                .accessibilityHint("Starts a new syllable challenge.")
            }

            // Feedback
            if let isCorrect = viewModel.isCorrect {
                Label(
                    isCorrect ? "Correct!" : "Try again",
                    systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.title3)
                .foregroundStyle(isCorrect ? .green : .red)
            }

            // Score
            if viewModel.attempts > 0 {
                Text("Score: \(viewModel.correctCount)/\(viewModel.attempts)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            viewModel.generateRandomTarget()
        }
    }

    private var composedDisplay: some View {
        VStack {
            if let char = viewModel.composedCharacter {
                Text(String(char))
                    .font(.system(size: 72, weight: .bold))
                    .frame(width: 100, height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .accessibilityLabel("Composed character \(String(char))")
            } else {
                Text("?")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .accessibilityLabel("No character composed yet")
            }
        }
    }

    private func slotView(position: JamoPosition, jamo: JamoEntry?, label: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.blue.opacity(0.5))
                    .frame(width: 68, height: 68)

                if let jamo = jamo {
                    Button {
                        viewModel.removeJamo(from: position)
                    } label: {
                        Text(String(jamo.character))
                            .font(.system(size: 32, weight: .bold))
                            .frame(width: 68, height: 68)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(String(jamo.character)) in the \(label.lowercased()) slot")
                    .accessibilityHint("Double tap to remove it from this slot.")
                } else {
                    Text("Drop here")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.8))
                        .frame(width: 68, height: 68)
                        .accessibilityLabel("\(label) slot is empty")
                        .accessibilityHint("Drag a jamo here or double tap a tile to place it.")
                }
            }
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in
                guard let id = items.first,
                      let entry = HangulData.jamo(for: id) else { return false }
                viewModel.placeJamo(entry, in: position)
                return true
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                position == .initial ? "Initial consonant slot" :
                position == .medial ? "Medial vowel slot" :
                "Final consonant slot"
            )
            .accessibilityValue(jamo.map { String($0.character) } ?? "Empty")
        }
    }

    private func jamoTile(_ jamo: JamoEntry) -> some View {
        Button {
            // Auto-place: consonants go to initial/final, vowels go to medial
            if jamo.positionRules.contains(.medial) {
                viewModel.placeJamo(jamo, in: .medial)
            } else if viewModel.initialSlot == nil && jamo.positionRules.contains(.initial) {
                viewModel.placeJamo(jamo, in: .initial)
            } else if jamo.positionRules.contains(.final_) {
                viewModel.placeJamo(jamo, in: .final_)
            }
        } label: {
            Text(String(jamo.character))
                .font(.system(size: 24, weight: .medium))
                .frame(width: 48, height: 48)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .draggable(jamo.id)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(KoreanAccessibility.jamoDescription(jamo.character))
        .accessibilityHint("Double tap to add this jamo to the syllable builder. You can also drag it.")
    }
}
