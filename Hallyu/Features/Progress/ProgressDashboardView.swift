import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProgressViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading progress...")
                } else {
                    scrollContent
                }
            }
            .navigationTitle("Progress")
            .onAppear { loadData() }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                cefrLevelSection
                statsOverview
                skillBreakdownSection
                vocabularyGrowthSection
                studyMinutesSection
                accuracyTrendSection

                NavigationLink(destination: CEFRMilestoneView(currentLevel: viewModel.cefrLevel, skillBreakdowns: viewModel.skillBreakdowns)) {
                    milestoneBanner
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    // MARK: - CEFR Level

    private var cefrLevelSection: some View {
        VStack(spacing: 12) {
            Text(viewModel.cefrLevel.rawValue)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(cefrColor(viewModel.cefrLevel))

            Text(cefrDescription(viewModel.cefrLevel))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(cefrColor(viewModel.cefrLevel).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            statCard(title: "Streak", value: "\(viewModel.streak)", icon: "flame.fill", color: .orange)
            statCard(title: "Study Time", value: formatStudyTime(viewModel.totalStudyMinutes), icon: "clock.fill", color: .blue)
            statCard(title: "Vocabulary", value: "\(viewModel.totalVocabularyCount)", icon: "textformat.abc", color: .purple)
        }
    }

    // MARK: - Skill Breakdown

    private var skillBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills")
                .font(.headline)

            ForEach(viewModel.skillBreakdowns) { skill in
                skillRow(skill)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func skillRow(_ skill: SkillBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(skill.displayName)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(skill.accuracy * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(skillColor(skill.accuracy))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(skillColor(skill.accuracy))
                        .frame(width: max(0, geo.size.width * skill.accuracy), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Vocabulary Growth Chart

    private var vocabularyGrowthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vocabulary Growth")
                .font(.headline)

            if viewModel.vocabularyGrowth.isEmpty {
                Text("No vocabulary data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                barChart(
                    data: viewModel.vocabularyGrowth.suffix(14).map { Double($0.count) },
                    color: .purple,
                    height: 100
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Study Minutes Chart

    private var studyMinutesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Study Minutes")
                .font(.headline)

            let hasData = viewModel.dailyStudyMinutes.contains { $0.minutes > 0 }
            if !hasData {
                Text("No study data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                barChart(
                    data: viewModel.dailyStudyMinutes.map { Double($0.minutes) },
                    color: .blue,
                    height: 100
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Accuracy Trend Chart

    private var accuracyTrendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accuracy Trend")
                .font(.headline)

            let hasData = viewModel.accuracyTrends.contains { $0.accuracy > 0 }
            if !hasData {
                Text("No accuracy data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                barChart(
                    data: viewModel.accuracyTrends.map { $0.accuracy * 100 },
                    color: .green,
                    height: 100
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Milestone Banner

    private var milestoneBanner: some View {
        HStack {
            Image(systemName: "flag.checkered")
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("CEFR Milestones")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("View your learning milestones")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Simple Bar Chart

    private func barChart(data: [Double], color: Color, height: CGFloat) -> some View {
        let maxVal = data.max() ?? 1.0
        let safeMax = maxVal > 0 ? maxVal : 1.0

        return GeometryReader { geo in
            HStack(alignment: .bottom, spacing: max(1, (geo.size.width - CGFloat(data.count) * 8) / CGFloat(max(data.count - 1, 1)))) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 8, height: max(2, CGFloat(value / safeMax) * height))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: height)
    }

    // MARK: - Stat Card

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func cefrColor(_ level: AppState.CEFRLevel) -> Color {
        switch level {
        case .preA1: return .gray
        case .a1: return .green
        case .a2: return .blue
        case .b1: return .purple
        case .b2: return .orange
        }
    }

    private func cefrDescription(_ level: AppState.CEFRLevel) -> String {
        switch level {
        case .preA1: return "Beginner — Learning the Korean alphabet"
        case .a1: return "Elementary — Can understand basic greetings"
        case .a2: return "Pre-Intermediate — Can follow scaffolded media"
        case .b1: return "Intermediate — Can follow K-drama with Korean subtitles"
        case .b2: return "Upper Intermediate — Can understand without subtitles"
        }
    }

    private func skillColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.5 { return .orange }
        return .red
    }

    private func formatStudyTime(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    // MARK: - Data Loading

    private func loadData() {
        let profileDescriptor = FetchDescriptor<LearnerProfile>()
        let profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
        guard let profile = profiles.first else { return }

        let skillDescriptor = FetchDescriptor<SkillMastery>()
        let skills = (try? modelContext.fetch(skillDescriptor)) ?? []

        let sessionDescriptor = FetchDescriptor<StudySession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        let reviewDescriptor = FetchDescriptor<ReviewItem>()
        let reviewItems = (try? modelContext.fetch(reviewDescriptor)) ?? []

        viewModel.loadProgress(
            profile: profile,
            skillMasteries: skills,
            studySessions: sessions,
            reviewItems: reviewItems
        )
    }
}
