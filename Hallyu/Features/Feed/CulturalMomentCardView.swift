import SwiftUI

struct CulturalMomentCardView: View {
    let info: CulturalMomentInfo
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var hasAutoCompleted = false

    var body: some View {
        VStack(spacing: 0) {
            if showContent {
                VStack(spacing: 24) {
                    // Badge
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                        Text("Did you know?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.orange.opacity(0.12), in: Capsule())
                    .transition(.scale.combined(with: .opacity))

                    // Title
                    Text(info.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    // Divider
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 40, height: 2)
                        .transition(.opacity)

                    // Body text
                    Text(info.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    // Source attribution
                    if !info.mediaSource.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: contentTypeIcon)
                                .font(.caption2)
                            Text("From: \(info.mediaSource)")
                                .font(.caption)
                        }
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .transition(.opacity)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                showContent = true
            }
            autoAdvance()
        }
        .accessibilityLabel("Cultural moment: \(info.title). \(info.body)")
    }

    private var contentTypeIcon: String {
        switch info.mediaContentType {
        case "drama": return "film"
        case "music": return "music.note"
        case "news": return "newspaper"
        default: return "play.rectangle"
        }
    }

    private func autoAdvance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard !hasAutoCompleted else { return }
            hasAutoCompleted = true
            onComplete()
        }
    }
}
