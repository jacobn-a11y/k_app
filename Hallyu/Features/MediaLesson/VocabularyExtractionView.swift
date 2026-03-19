import SwiftUI

/// Step 5.1 (sub-step 5): User selects which new words to add to SRS for review.
struct VocabularyExtractionView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MediaLessonViewModel
    @State private var lastAddedCount: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            wordList
            bottomBar
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Save New Words")
                .font(.title2)
                .fontWeight(.bold)

            Text("Select words you want to review later. They'll be added to your spaced repetition deck.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button("Select All") { viewModel.selectAllWords() }
                    .font(.caption)
                Spacer()
                Button("Deselect All") { viewModel.deselectAllWords() }
                    .font(.caption)
            }
        }
        .padding()
    }

    // MARK: - Word List

    private var wordList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.extractedWords) { word in
                    wordRow(word)
                }
            }
            .padding(.horizontal)
        }
    }

    private func wordRow(_ word: MediaLessonViewModel.ExtractedWord) -> some View {
        let isSelected = viewModel.selectedWordIds.contains(word.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleWordSelection(word.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accentColor : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(word.korean)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(word.english)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let rank = word.frequencyRank {
                    Text("#\(rank)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                Text("\(viewModel.selectedWordCount) words selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    lastAddedCount = viewModel.addSelectedWordsToSRS(modelContext: modelContext)
                } label: {
                    Label("Add to Review", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedWordIds.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if lastAddedCount > 0 {
                Text("\(lastAddedCount) new word\(lastAddedCount == 1 ? "" : "s") added to review.")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.bottom, 8)
            }
        }
    }
}
