import SwiftUI

struct GrammarExplainerView: View {
    @Bindable var viewModel: GrammarExplainerViewModel
    let userId: UUID

    @State private var answerText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(.purple)
                Text("Grammar Explainer")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            // Pattern
            Text(viewModel.pattern)
                .font(.title2)
                .fontWeight(.bold)

            // Context
            Text(viewModel.mediaContext)
                .font(.body)
                .foregroundStyle(.secondary)
                .italic()

            switch viewModel.phase {
            case .idle:
                EmptyView()

            case .retrievalFirst:
                VStack(spacing: 12) {
                    Text(viewModel.retrievalQuestion)
                        .font(.body)
                        .multilineTextAlignment(.center)

                    TextField("Your answer...", text: $answerText)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Show me") {
                            Task { await viewModel.requestExplanation() }
                        }
                        .buttonStyle(.bordered)

                        Button("Submit") {
                            viewModel.submitAnswer(answerText)
                            Task { await viewModel.requestExplanation() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(answerText.isEmpty)
                    }
                }

            case .awaitingAnswer, .loading:
                ProgressView("Analyzing grammar...")
                    .padding()

            case .showingExplanation:
                if let explanation = viewModel.explanation {
                    grammarExplanationView(explanation)
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
    private func grammarExplanationView(_ explanation: GrammarExplanation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rule statement
            VStack(alignment: .leading, spacing: 2) {
                Text("Rule")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(explanation.ruleStatement)
                    .font(.body)
                    .fontWeight(.medium)
            }

            // Explanation
            Text(explanation.explanation)
                .font(.body)

            // Contrastive example
            VStack(alignment: .leading, spacing: 2) {
                Text("Compare")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(explanation.contrastiveExample)
                    .font(.body)
                    .padding(8)
                    .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }

            // Retrieval question
            VStack(alignment: .leading, spacing: 2) {
                Text("Check your understanding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(explanation.retrievalQuestion)
                    .font(.body)
                    .italic()
            }

            Button {
                Task { await viewModel.trackGrammarPattern(userId: userId) }
            } label: {
                Label("Track this pattern", systemImage: "bookmark")
            }
            .buttonStyle(.bordered)
        }
    }
}
