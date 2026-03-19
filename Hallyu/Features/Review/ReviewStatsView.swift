import SwiftUI

struct ReviewStatsView: View {
    let stats: ReviewSessionViewModel.SessionStats
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: headerIcon)
                    .scaledFont(size: 56)
                    .foregroundStyle(headerColor)

                Text(headerMessage)
                    .font(.title.bold())

                Text(subMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 16) {
                statCard(
                    title: "Accuracy",
                    value: "\(Int(stats.accuracy * 100))%",
                    icon: "target",
                    color: stats.accuracy >= 0.8 ? .green : stats.accuracy >= 0.6 ? .orange : .red
                )

                statCard(
                    title: "Best Streak",
                    value: "\(stats.streak)",
                    icon: "flame.fill",
                    color: .orange
                )

                statCard(
                    title: "Reviewed",
                    value: "\(stats.totalItems)",
                    icon: "square.stack.fill",
                    color: .blue
                )

                statCard(
                    title: "Avg Speed",
                    value: formatTime(stats.averageResponseTime),
                    icon: "timer",
                    color: .purple
                )
            }
            .padding(.horizontal)

            // Correct / Incorrect bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        if stats.correctCount > 0 {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geo.size.width * stats.accuracy)
                        }
                        if stats.incorrectCount > 0 {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * (1.0 - stats.accuracy))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 8)
                .padding(.horizontal)

                HStack {
                    Label("\(stats.correctCount) correct", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                    Spacer()
                    Label("\(stats.incorrectCount) incorrect", systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                }
                .font(.caption)
                .padding(.horizontal)
            }

            // Duration
            Text("Session: \(formatDuration(stats.totalDuration))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Helpers

    private var headerIcon: String {
        if stats.accuracy >= 0.9 { return "star.fill" }
        if stats.accuracy >= 0.7 { return "hand.thumbsup.fill" }
        return "arrow.up.circle.fill"
    }

    private var headerColor: Color {
        if stats.accuracy >= 0.9 { return .yellow }
        if stats.accuracy >= 0.7 { return .green }
        return .blue
    }

    private var headerMessage: String {
        if stats.accuracy >= 0.9 { return "Excellent!" }
        if stats.accuracy >= 0.7 { return "Good work!" }
        return "Keep going!"
    }

    private var subMessage: String {
        if stats.accuracy >= 0.9 { return "You're mastering this material" }
        if stats.accuracy >= 0.7 { return "Solid review session" }
        return "Practice makes perfect"
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 1 { return "<1s" }
        if seconds < 10 { return String(format: "%.1fs", seconds) }
        return "\(Int(seconds))s"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}
