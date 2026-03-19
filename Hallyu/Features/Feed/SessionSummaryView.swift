import SwiftUI

struct SessionSummaryView: View {
    let cardsCompleted: Int
    let totalXP: Int
    let sessionDurationSeconds: Int
    let consecutiveCorrect: Int
    let goalReached: Bool
    let onDismiss: () -> Void

    @State private var showStats = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: goalReached ? "star.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(goalReached ? .yellow : .accentColor)

                Text(goalReached ? "Great Session!" : "Session Paused")
                    .font(.title)
                    .fontWeight(.bold)
            }

            if showStats {
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatTile(
                        icon: "rectangle.stack.fill",
                        value: "\(cardsCompleted)",
                        label: "Cards",
                        color: .purple
                    )

                    StatTile(
                        icon: "sparkles",
                        value: "\(totalXP)",
                        label: "XP Earned",
                        color: .accentColor
                    )

                    StatTile(
                        icon: "clock.fill",
                        value: formattedDuration,
                        label: "Time",
                        color: .green
                    )

                    StatTile(
                        icon: "flame.fill",
                        value: "\(consecutiveCorrect)",
                        label: "Best Streak",
                        color: .orange
                    )
                }
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    onDismiss()
                } label: {
                    Text("Continue Learning")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.accentColor, in: RoundedRectangle(cornerRadius: 14))
                }
                .frame(minHeight: 44)

                Button {
                    onDismiss()
                } label: {
                    Text("Done for now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.2)) {
                showStats = true
            }
        }
        .accessibilityLabel("Session summary. \(cardsCompleted) cards completed, \(totalXP) XP earned, \(formattedDuration) spent studying.")
    }

    private var formattedDuration: String {
        let minutes = sessionDurationSeconds / 60
        let seconds = sessionDurationSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
