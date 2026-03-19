import SwiftUI

struct GrammarFeedCard: View {
    let info: GrammarSnapInfo
    let onComplete: (Bool) -> Void

    @State private var selectedIndex: Int?
    @State private var hasAnswered = false

    var body: some View {
        VStack(spacing: 28) {
            Text("Grammar")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            // Pattern display
            Text(info.pattern)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.accentColor)

            // Example sentence
            VStack(spacing: 6) {
                Text(info.exampleSentence)
                    .font(.title3)
                    .multilineTextAlignment(.center)

                Text(info.translation)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            // Question
            Text("What does this pattern express?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Options
            VStack(spacing: 10) {
                ForEach(Array(info.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        guard !hasAnswered else { return }
                        selectOption(index)
                    } label: {
                        HStack {
                            Text(option)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(optionTextColor(for: index))

                            Spacer()

                            if hasAnswered {
                                if index == info.correctOptionIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if index == selectedIndex {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(optionBackground(for: index))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityLabel("\(option)\(hasAnswered && index == info.correctOptionIndex ? ", correct answer" : "")")
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func selectOption(_ index: Int) {
        selectedIndex = index
        hasAnswered = true
        let correct = index == info.correctOptionIndex

        // Delay to show result before completing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onComplete(correct)
        }
    }

    private func optionTextColor(for index: Int) -> Color {
        guard hasAnswered else { return .primary }
        if index == info.correctOptionIndex { return .green }
        if index == selectedIndex { return .red }
        return .secondary
    }

    private func optionBackground(for index: Int) -> Color {
        if !hasAnswered {
            if index == selectedIndex {
                return Color.accentColor.opacity(0.1)
            }
            return Color.secondary.opacity(0.08)
        }

        if index == info.correctOptionIndex {
            return Color.green.opacity(0.15)
        }
        if index == selectedIndex && index != info.correctOptionIndex {
            return Color.red.opacity(0.15)
        }
        return Color.secondary.opacity(0.05)
    }
}

// MARK: - Goal Reached Celebration Card

struct GoalReachedCard: View {
    let xpEarned: Int
    let cardsCompleted: Int

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 24) {
            if showContent {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.yellow)
                    .transition(.scale.combined(with: .opacity))

                Text("Daily Goal Reached!")
                    .font(.title)
                    .fontWeight(.bold)
                    .transition(.opacity)

                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(xpEarned)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.accentColor)
                        Text("XP earned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 4) {
                        Text("\(cardsCompleted)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.accentColor)
                        Text("cards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Text("Keep going for bonus XP!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
        }
        .accessibilityLabel("Congratulations! Daily goal reached. \(xpEarned) XP earned, \(cardsCompleted) cards completed.")
    }
}
