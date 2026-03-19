import SwiftUI

struct MediaClipFeedCard: View {
    let clipInfo: MediaClipInfo
    let services: ServiceContainer
    let onComplete: () -> Void

    @State private var isPlaying = false
    @State private var showTranslation = true
    @State private var hasAutoCompleted = false

    var body: some View {
        VStack(spacing: 0) {
            // Content type badge
            HStack {
                Label(clipInfo.contentType.capitalized, systemImage: contentTypeIcon)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Text(clipInfo.title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            // Korean text (large, centered)
            VStack(spacing: 16) {
                Text(clipInfo.segment.textKr)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Korean text: \(clipInfo.segment.textKr)")

                // English translation (toggleable)
                if showTranslation {
                    Text(clipInfo.segment.textEn)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 24) {
                // Play/replay button
                Button {
                    playSegment()
                } label: {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.white.opacity(0.2)))
                }
                .accessibilityLabel(isPlaying ? "Playing audio" : "Play audio")
                .frame(minWidth: 56, minHeight: 56)

                // Toggle translation
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTranslation.toggle()
                    }
                } label: {
                    Image(systemName: showTranslation ? "text.bubble.fill" : "text.bubble")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .accessibilityLabel(showTranslation ? "Hide translation" : "Show translation")
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.bottom, 80)
        }
        .onAppear {
            autoAdvance()
        }
    }

    private var contentTypeIcon: String {
        switch clipInfo.contentType {
        case "drama": return "film"
        case "music": return "music.note"
        case "news": return "newspaper"
        case "webtoon": return "book.pages"
        case "short_video": return "video"
        default: return "play.rectangle"
        }
    }

    private func playSegment() {
        guard !isPlaying, let url = URL(string: clipInfo.mediaUrl), !clipInfo.mediaUrl.isEmpty else { return }
        isPlaying = true
        Task {
            do {
                try await services.mediaPlayer.loadMedia(url: url)
                let startSeconds = Double(clipInfo.segment.startMs) / 1000.0
                await services.mediaPlayer.seek(to: startSeconds)
                await services.mediaPlayer.play()

                // Auto-stop after segment duration
                let durationMs = clipInfo.segment.endMs - clipInfo.segment.startMs
                try? await Task.sleep(for: .milliseconds(durationMs))
                await services.mediaPlayer.pause()
                isPlaying = false
            } catch {
                isPlaying = false
            }
        }
    }

    private func autoAdvance() {
        // Auto-complete after 3 seconds (user can swipe earlier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard !hasAutoCompleted else { return }
            hasAutoCompleted = true
            onComplete()
        }
    }
}
