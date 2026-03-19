import SwiftUI

struct ComprehensionCoachView: View {
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
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Task { await viewModel.addToReview(userId: userId) }
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
}
