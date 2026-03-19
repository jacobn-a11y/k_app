import SwiftUI

struct ReviewSessionView: View {
    @State private var viewModel: ReviewSessionViewModel
    @Environment(\.dismiss) private var dismiss

    // ViewModel created at init time to capture service references
    init(items: [ReviewItem], services: ServiceContainer) {
        _viewModel = State(initialValue: ReviewSessionViewModel(
            items: items,
            srsEngine: services.srsEngine,
            learnerModel: services.learnerModel
        ))
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isSessionComplete {
                    ReviewStatsView(stats: viewModel.computeStats()) {
                        dismiss()
                    }
                } else if let item = viewModel.currentItem {
                    reviewContent(for: item)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        ProgressView(value: viewModel.progress)
                            .frame(width: 120)
                        Text("\(viewModel.remainingCount) remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reviewContent(for item: ReviewItem) -> some View {
        VStack(spacing: 24) {
            // Streak indicator
            if viewModel.currentStreak > 2 {
                Label("\(viewModel.currentStreak) streak!", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            Spacer()

            // Flashcard
            FlashcardView(isFlipped: viewModel.isShowingAnswer) {
                // Front: prompt
                VStack(spacing: 12) {
                    promptIcon(for: item.itemType)
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text(displayText(for: item))
                        .scaledFont(size: 48, weight: .bold)

                    Text(item.itemType.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    if !viewModel.isShowingAnswer {
                        Text("Tap to reveal")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            } back: {
                // Back: answer
                VStack(spacing: 12) {
                    Text(displayText(for: item))
                        .scaledFont(size: 36, weight: .bold)

                    Divider()

                    Text(answerText(for: item))
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("Tap to flip back")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 280)
            .padding(.horizontal, 24)
            .onTapGesture {
                if !viewModel.isShowingAnswer {
                    viewModel.revealAnswer()
                }
            }

            Spacer()

            // Answer buttons (shown after reveal)
            if viewModel.isShowingAnswer {
                HStack(spacing: 16) {
                    Button {
                        viewModel.submitAnswer(wasCorrect: false)
                    } label: {
                        Label("Again", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        viewModel.submitAnswer(wasCorrect: true)
                    } label: {
                        Label("Got it", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
            } else {
                // Skip button
                Button("Skip") {
                    viewModel.skipItem()
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

        }
        .safeAreaInset(edge: .bottom) {
            // Score bar
            HStack {
                Label("\(viewModel.correctCount)", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                Spacer()
                Label("\(viewModel.incorrectCount)", systemImage: "xmark.circle")
                    .foregroundStyle(.red)
            }
            .font(.caption)
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    private func promptIcon(for itemType: String) -> Image {
        switch itemType {
        case let t where t.contains("hangul"):
            return Image(systemName: "character.ko")
        case let t where t.contains("vocab"):
            return Image(systemName: "text.book.closed")
        case let t where t.contains("grammar"):
            return Image(systemName: "text.alignleft")
        case let t where t.contains("listening"):
            return Image(systemName: "ear")
        default:
            return Image(systemName: "questionmark.circle")
        }
    }

    private func displayText(for item: ReviewItem) -> String {
        // In production, this would look up the actual content from the item's reference
        item.itemType.contains("hangul") ? "한" : item.itemId.uuidString.prefix(4).uppercased()
    }

    private func answerText(for item: ReviewItem) -> String {
        item.itemType.contains("hangul") ? "han" : "Answer"
    }
}
