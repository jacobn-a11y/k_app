import SwiftUI

struct VocabFeedCard: View {
    let info: VocabCardInfo
    let onComplete: (Bool) -> Void

    @State private var isFlipped = false
    @State private var hasAnswered = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("Vocabulary")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            // Flashcard using existing FlashcardView
            FlashcardView(
                isFlipped: isFlipped,
                onTap: { isFlipped.toggle() }
            ) {
                // Front: Korean word
                VStack(spacing: 12) {
                    Text(info.promptText)
                        .font(.system(size: 36, weight: .medium))
                        .multilineTextAlignment(.center)

                    if !info.sourceContext.isEmpty {
                        Text(info.sourceContext)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Text("Tap to flip")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                }
            } back: {
                // Back: English meaning
                VStack(spacing: 12) {
                    Text(info.answerText)
                        .font(.system(size: 28, weight: .medium))
                        .multilineTextAlignment(.center)

                    if !info.sourceContext.isEmpty {
                        Text(info.sourceContext)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 20)
            .offset(x: dragOffset)
            .rotationEffect(.degrees(Double(dragOffset) / 20))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard isFlipped && !hasAnswered else { return }
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        guard isFlipped && !hasAnswered else {
                            dragOffset = 0
                            return
                        }
                        if abs(value.translation.width) > 80 {
                            let correct = value.translation.width > 0
                            hasAnswered = true
                            withAnimation(.spring(response: 0.3)) {
                                dragOffset = correct ? 300 : -300
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onComplete(correct)
                            }
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                dragOffset = 0
                            }
                        }
                    }
            )

            if isFlipped && !hasAnswered {
                HStack(spacing: 32) {
                    // Wrong button
                    Button {
                        hasAnswered = true
                        withAnimation(.spring(response: 0.3)) { dragOffset = -300 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete(false) }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("I didn't know this")
                    .frame(minWidth: 44, minHeight: 44)

                    // Correct button
                    Button {
                        hasAnswered = true
                        withAnimation(.spring(response: 0.3)) { dragOffset = 300 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete(true) }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.green)
                    }
                    .accessibilityLabel("I knew this")
                    .frame(minWidth: 44, minHeight: 44)
                }
                .transition(.opacity)
            }

            if !isFlipped {
                Text("Tap card to reveal answer")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
