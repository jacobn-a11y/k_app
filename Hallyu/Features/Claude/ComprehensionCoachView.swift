import SwiftUI
import SwiftData

struct ComprehensionCoachView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: ComprehensionCoachViewModel
    let transcript: String
    let learnerLevel: String
    let knownVocabulary: [String]
    let userId: UUID

    @State private var guessText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Comprehension Coach")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            // Target word
            Text(viewModel.targetWord)
                .font(.title)
                .fontWeight(.bold)

            switch viewModel.phase {
            case .idle:
                EmptyView()

            case .retrievalPrompt:
                VStack(spacing: 12) {
                    Text(viewModel.retrievalPromptText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    TextField("Your guess...", text: $guessText)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Skip") {
                            Task {
                                await viewModel.requestExplanation(
                                    transcript: transcript,
                                    learnerLevel: learnerLevel,
                                    knownVocabulary: knownVocabulary
                                )
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Submit Guess") {
                            viewModel.submitGuess(guessText)
                            Task {
                                await viewModel.requestExplanation(
                                    transcript: transcript,
                                    learnerLevel: learnerLevel,
                                    knownVocabulary: knownVocabulary
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(guessText.isEmpty)
                    }
                }

            case .awaitingGuess, .loading:
                ProgressView("Asking Claude...")
                    .padding()

            case .showingResult:
                if let response = viewModel.response {
                    comprehensionResultView(response)
                }

            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await viewModel.requestExplanation(
                                transcript: transcript,
                                learnerLevel: learnerLevel,
                                knownVocabulary: knownVocabulary
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func comprehensionResultView(_ response: ComprehensionResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.guessWasClose {
                Label("Nice guess!", systemImage: "star.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            }

            explanationRow(title: "Literal meaning", value: response.literalMeaning)
            explanationRow(title: "In context", value: response.contextualMeaning)
            explanationRow(title: "Example", value: response.simplerExample)

            if let grammar = response.grammarPattern {
                explanationRow(title: "Grammar", value: grammar)
            }

            if let register = response.registerNote {
                explanationRow(title: "Register", value: register)
            }

            if !viewModel.addedToReview {
                Button {
                    Task {
                        await viewModel.addToReview(userId: userId)
                        persistReviewItem()
                    }
                } label: {
                    Label("Add to Review", systemImage: "plus.circle")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Label("Added to Review", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private func explanationRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }

    private func persistReviewItem() {
        guard let response = viewModel.response else { return }
        let wordId = deterministicUUID(for: "claude_word_\(viewModel.targetWord)")

        let existingItems = (try? modelContext.fetch(FetchDescriptor<ReviewItem>())) ?? []
        let exists = existingItems.contains {
            $0.userId == userId &&
            $0.itemType == "vocabulary" &&
            $0.itemId == wordId
        }
        if exists {
            return
        }

        let reviewItem = ReviewItem(
            userId: userId,
            itemType: "vocabulary",
            itemId: wordId,
            promptText: viewModel.targetWord,
            answerText: response.contextualMeaning,
            sourceContext: viewModel.mediaTitle
        )
        modelContext.insert(reviewItem)
        try? modelContext.save()
    }

    private func deterministicUUID(for value: String) -> UUID {
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        let bytes = withUnsafeBytes(of: hash.bigEndian) { Array($0) }
        var uuidBytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<8 {
            uuidBytes[i] = bytes[i]
            uuidBytes[i + 8] = bytes[i] ^ 0x5A
        }
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x40
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
    }
}
