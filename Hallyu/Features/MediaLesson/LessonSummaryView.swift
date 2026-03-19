import SwiftUI
import SwiftData

/// Step 5.1 (sub-step 7): Session summary showing words learned, accuracy, time spent.
struct LessonSummaryView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MediaLessonViewModel
    @State private var showReviewSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsGrid
                detailsSection
                actionButtons
            }
            .padding()
        }
        .onAppear {
            viewModel.saveStudySessionIfNeeded(modelContext: modelContext)
            viewModel.buildSummary()
        }
        .navigationDestination(isPresented: $showReviewSession) {
            ReviewSessionView(items: newReviewItems, services: services)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .scaledFont(size: 64)
                .foregroundStyle(.yellow)

            Text("Lesson Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let summary = viewModel.sessionSummary {
                Text(summary.contentTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let summary = viewModel.sessionSummary

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            statCard(
                icon: "clock.fill",
                value: formatDuration(summary?.totalDurationSeconds ?? 0),
                label: "Time Spent",
                color: .blue
            )

            statCard(
                icon: "brain.head.profile",
                value: "\(Int((summary?.comprehensionScore ?? 0) * 100))%",
                label: "Comprehension",
                color: comprehensionColor(summary?.comprehensionScore ?? 0)
            )

            statCard(
                icon: "text.book.closed.fill",
                value: "\(summary?.wordsAddedToSRS ?? 0)",
                label: "Words Saved",
                color: .purple
            )

            statCard(
                icon: "waveform",
                value: "\(summary?.sentencesShadowed ?? 0)",
                label: "Sentences Shadowed",
                color: .orange
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            if let summary = viewModel.sessionSummary {
                detailRow(
                    label: "Words pre-taught",
                    value: "\(summary.wordsPreTaught)",
                    detail: "\(summary.wordsKnown) already known"
                )

                detailRow(
                    label: "Comprehension questions",
                    value: "\(viewModel.comprehensionAnswers.count)",
                    detail: "\(viewModel.comprehensionAnswers.filter { $0.wasCorrect }.count) correct"
                )

                if summary.sentencesShadowed > 0 {
                    detailRow(
                        label: "Shadowing practice",
                        value: "\(summary.sentencesShadowed) sentences",
                        detail: nil
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func detailRow(label: String, value: String, detail: String?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showReviewSession = true
            } label: {
                Label("Review New Words", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(newReviewItems.isEmpty)

            Button {
                dismiss()
            } label: {
                Text("Back to Library")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }

    private func comprehensionColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.6 { return .orange }
        return .red
    }

    private var newReviewItems: [ReviewItem] {
        guard !viewModel.persistedWordIds.isEmpty else { return [] }
        let descriptor = FetchDescriptor<ReviewItem>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        return items.filter {
            $0.userId == viewModel.userId &&
            $0.itemType == "vocabulary" &&
            viewModel.persistedWordIds.contains($0.itemId)
        }
    }
}
