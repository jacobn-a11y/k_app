import SwiftUI
import SwiftData

struct GrammarExplainerView: View {
    @Environment(\.modelContext) private var modelContext
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
                Task {
                    await viewModel.trackGrammarPattern(userId: userId)
                    await MainActor.run {
                        persistReviewItem()
                    }
                }
            } label: {
                Label("Track this pattern", systemImage: "bookmark")
            }
            .buttonStyle(.bordered)
        }
    }

    private func persistReviewItem() {
        guard let explanation = viewModel.explanation else { return }
        let grammarId = deterministicUUID(for: "claude_grammar_\(viewModel.pattern)")

        let existing = (try? modelContext.fetch(FetchDescriptor<ReviewItem>())) ?? []
        let duplicate = existing.contains {
            $0.userId == userId &&
            $0.itemType == "grammar" &&
            $0.itemId == grammarId
        }
        if duplicate {
            return
        }

        let item = ReviewItem(
            userId: userId,
            itemType: "grammar",
            itemId: grammarId,
            promptText: viewModel.pattern,
            answerText: explanation.ruleStatement,
            sourceContext: viewModel.mediaContext
        )
        modelContext.insert(item)
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
            uuidBytes[i + 8] = bytes[i] ^ 0x33
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
