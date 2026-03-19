import SwiftUI

/// Step 5.2: Flashcard-style vocabulary pre-teaching before media consumption.
/// Shows 5-8 words that will appear in the upcoming media.
struct VocabularyPreTeachView: View {
    @Bindable var viewModel: MediaLessonViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            if let word = viewModel.currentPreTaskWord {
                Spacer()

                progressIndicator

                flashcard(for: word)

                actionButtons

                Spacer()
            } else {
                preTaskCompleteView
            }
        }
        .padding()
    }

    // MARK: - Progress

    private var progressIndicator: some View {
        HStack {
            Text("\(viewModel.preTaskCurrentIndex + 1) / \(viewModel.preTaskWords.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Show known/unknown counts
            HStack(spacing: 12) {
                Label("\(viewModel.preTaskResults.filter { $0.knewIt }.count)", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                Label("\(viewModel.preTaskResults.filter { !$0.knewIt }.count)", systemImage: "xmark.circle")
                    .foregroundStyle(.orange)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Flashcard

    private func flashcard(for word: MediaLessonViewModel.PreTaskWord) -> some View {
        VStack(spacing: 16) {
            // Korean word (always visible)
            Text(word.korean)
                .scaledFont(size: 48, weight: .bold)
                .minimumScaleFactor(0.5)

            if viewModel.preTaskShowingAnswer {
                VStack(spacing: 8) {
                    if !word.romanization.isEmpty {
                        Text(word.romanization)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Text(word.english)
                        .font(.title2)
                        .fontWeight(.medium)

                    if !word.partOfSpeech.isEmpty {
                        Text(word.partOfSpeech)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("What do you think this means?")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Group {
            if viewModel.preTaskShowingAnswer {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut) { viewModel.submitPreTaskAnswer(knewIt: false) }
                    } label: {
                        Label("Didn't know", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)

                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut) { viewModel.submitPreTaskAnswer(knewIt: true) }
                    } label: {
                        Label("Knew it!", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            } else {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut) { viewModel.revealPreTaskAnswer() }
                } label: {
                    Text("Reveal Answer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Complete

    private var preTaskCompleteView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Vocabulary Preview Complete!")
                .font(.title2)
                .fontWeight(.bold)

            let known = viewModel.preTaskResults.filter { $0.knewIt }.count
            let total = viewModel.preTaskResults.count
            Text("You knew \(known) out of \(total) words")
                .font(.body)
                .foregroundStyle(.secondary)

            if known < total {
                Text("Don't worry \u{2014} you'll encounter these words in the media and can review them later.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}
