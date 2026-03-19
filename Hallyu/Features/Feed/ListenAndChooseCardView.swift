import SwiftUI

struct ListenAndChooseCardView: View {
    let info: ListenAndChooseInfo
    let services: ServiceContainer
    let onComplete: (Bool) -> Void

    @State private var selectedIndex: Int?
    @State private var hasAnswered = false
    @State private var isPlaying = false
    @State private var optionsRevealed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Listen & Choose")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            // Audio player area
            VStack(spacing: 16) {
                Button {
                    playAudio()
                } label: {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.accentColor.opacity(0.12))
                                .frame(width: 80, height: 80)

                            Image(systemName: isPlaying ? "speaker.wave.3.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.accentColor)
                                .symbolEffect(.variableColor, isActive: isPlaying)
                        }

                        Text(isPlaying ? "Playing..." : "Tap to listen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel(isPlaying ? "Audio playing" : "Play audio clip")
                .frame(minWidth: 80, minHeight: 80)

                // Korean text (shown after first play)
                if isPlaying || hasAnswered {
                    Text(info.audioSegmentKr)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            // Question
            Text("What does this mean?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Options (staggered reveal)
            if optionsRevealed {
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
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .accessibilityLabel("\(option)\(hasAnswered && index == info.correctOptionIndex ? ", correct answer" : "")")
                    }
                }
                .padding(.horizontal, 20)
            }

            // Show translation after answering
            if hasAnswered {
                Text(info.audioSegmentEn)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Auto-play audio on appear
            playAudio()
            // Staggered reveal of options
            withAnimation(.spring(response: 0.5).delay(0.5)) {
                optionsRevealed = true
            }
        }
    }

    private func playAudio() {
        guard !isPlaying, let url = URL(string: info.mediaUrl), !info.mediaUrl.isEmpty else { return }
        isPlaying = true
        Task {
            do {
                try await services.mediaPlayer.loadMedia(url: url)
                let startSeconds = Double(info.startMs) / 1000.0
                await services.mediaPlayer.seek(to: startSeconds)
                await services.mediaPlayer.play()

                let durationMs = info.endMs - info.startMs
                try? await Task.sleep(for: .milliseconds(durationMs))
                await services.mediaPlayer.pause()
                isPlaying = false
            } catch {
                isPlaying = false
            }
        }
    }

    private func selectOption(_ index: Int) {
        selectedIndex = index
        hasAnswered = true
        let correct = index == info.correctOptionIndex

        if correct {
            HapticManager.play(.success)
        } else {
            HapticManager.play(.error)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
