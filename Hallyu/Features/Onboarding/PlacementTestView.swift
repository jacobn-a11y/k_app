import SwiftUI

struct PlacementTestView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel = PlacementTestViewModel()
    let onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isComplete {
                    resultsView
                } else if let item = viewModel.currentItem {
                    questionView(item: item)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Placement Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !viewModel.isComplete {
                        Button("Skip Test") {
                            onComplete("pre-A1")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Question View

    private func questionView(item: PlacementTestViewModel.PlacementItem) -> some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 4) {
                ProgressView(value: viewModel.progressFraction)
                    .tint(.blue)
                Text("Question \(viewModel.currentItemIndex + 1) of \(viewModel.totalItems)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Spacer()

            // Prompt
            VStack(spacing: 12) {
                typeBadge(for: item.type)
                Text(item.prompt)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Options
            VStack(spacing: 10) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        viewModel.selectedOptionIndex = index
                        // Brief delay for visual feedback before advancing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.submitAnswer(optionIndex: index)
                        }
                    } label: {
                        HStack {
                            Text(optionLabel(index))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text(option)
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            viewModel.selectedOptionIndex == index
                                ? Color.blue.opacity(0.2)
                                : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)

            // Skip button
            Button("I don't know") {
                viewModel.skipItem()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding()
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Placement Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Level badge
                VStack(spacing: 8) {
                    Text("Your estimated level")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.estimatedLevel)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Score
                Text("\(viewModel.correctCount) / \(viewModel.totalAnswered) correct")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Skill breakdown
                if !viewModel.skillBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Skill Breakdown")
                            .font(.headline)

                        ForEach(Array(viewModel.skillBreakdown.sorted(by: { $0.key < $1.key })), id: \.key) { skill, accuracy in
                            HStack {
                                Text(skillLabel(skill))
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(accuracy * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            ProgressView(value: accuracy)
                                .tint(accuracy >= 0.6 ? .green : .orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                Button {
                    onComplete(viewModel.estimatedLevel)
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private func typeBadge(for type: PlacementTestViewModel.ItemType) -> some View {
        Text(typeLabel(type))
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }

    private func typeLabel(_ type: PlacementTestViewModel.ItemType) -> String {
        switch type {
        case .hangulReading: return "Hangul"
        case .vocabularyRecognition: return "Vocabulary"
        case .grammarMultipleChoice: return "Grammar"
        case .listeningComprehension: return "Listening"
        }
    }

    private func skillLabel(_ key: String) -> String {
        switch key {
        case "hangul_reading": return "Hangul Reading"
        case "vocabulary_recognition": return "Vocabulary"
        case "grammar_mc": return "Grammar"
        case "listening": return "Listening"
        default: return key
        }
    }

    private func optionLabel(_ index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }
}
