import SwiftUI

struct ContentView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner(
                isOffline: appState.isOffline,
                pendingSyncCount: appState.pendingSyncCount
            )

            TabView {
                Tab("Today", systemImage: "calendar") {
                    DailyPlanView()
                }
                Tab("Learn", systemImage: "book.fill") {
                    MediaLibraryView()
                }
                Tab("Review", systemImage: "arrow.counterclockwise") {
                    ReviewTabView()
                }
                Tab("Progress", systemImage: "chart.bar.fill") {
                    ProgressTabView()
                }
                Tab("Settings", systemImage: "gearshape.fill") {
                    SettingsView()
                }
            }
        }
        .onAppear {
            MediaContentSeeder.seedIfNeeded(modelContext: modelContext)
        }
    }
}

// MARK: - Review Tab (wired to ReviewSessionView)

struct ReviewTabView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var dueItems: [ReviewItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading reviews...")
                } else if dueItems.isEmpty {
                    emptyReviewState
                } else {
                    ReviewSessionView(items: dueItems, services: services)
                }
            }
            .navigationTitle("Review")
            .onAppear { loadDueItems() }
            .accessibilityLabel("Review tab")
        }
    }

    private var emptyReviewState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .scaledFont(size: 48)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("All caught up!")
                .font(.headline)
            Text("No items due for review right now. Keep learning to add more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func loadDueItems() {
        let descriptor = FetchDescriptor<ReviewItem>()
        let allItems = (try? modelContext.fetch(descriptor)) ?? []
        guard let userId = appState.currentUserId ?? allItems.first?.userId else {
            dueItems = []
            isLoading = false
            return
        }
        dueItems = services.srsEngine.getDueItems(for: userId, from: allItems, limit: 20)
        isLoading = false
    }
}

// MARK: - Progress Tab (wired to ProgressDashboard)

struct ProgressTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var stats = ProgressStats()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    cefrLevelCard
                    studyStatsCard
                    skillBreakdownCard
                    monthlyChallengeCard
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onAppear { loadStats() }
            .accessibilityLabel("Progress dashboard")
        }
    }

    private var cefrLevelCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Level")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            Text(appState.currentCEFRLevel.rawValue)
                .scaledFont(size: 48, weight: .bold)
                .accessibilityLabel("CEFR level \(appState.currentCEFRLevel.rawValue)")

            Text(cefrDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var studyStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Stats")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 16) {
                statItem(value: "\(stats.totalSessions)", label: "Sessions", icon: "book.fill")
                statItem(value: "\(stats.totalMinutes)", label: "Minutes", icon: "clock.fill")
                statItem(value: "\(stats.wordsLearned)", label: "Words", icon: "text.book.closed.fill")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var skillBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(stats.skills, id: \.name) { skill in
                HStack {
                    Text(skill.name)
                        .font(.subheadline)
                        .frame(width: 100, alignment: .leading)
                    ProgressView(value: skill.mastery)
                        .tint(skillColor(skill.mastery))
                    Text("\(Int(skill.mastery * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(skill.name): \(Int(skill.mastery * 100)) percent mastery")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var monthlyChallengeCard: some View {
        NavigationLink {
            MediaChallengeEntryView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Challenge")
                        .font(.headline)
                    Text("Assess CEFR progress with unseen media")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private func skillColor(_ mastery: Double) -> Color {
        if mastery >= 0.8 { return .green }
        if mastery >= 0.5 { return .blue }
        if mastery >= 0.3 { return .orange }
        return .red
    }

    private var cefrDescription: String {
        switch appState.currentCEFRLevel {
        case .preA1: return "Beginning your Korean journey"
        case .a1: return "Can understand basic greetings in dramas"
        case .a2: return "Can follow heavily scaffolded K-drama clips"
        case .b1: return "Can follow main plot with Korean subtitles"
        case .b2: return "Can understand K-drama without subtitles"
        }
    }

    private func loadStats() {
        let sessionDescriptor = FetchDescriptor<StudySession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        let skillDescriptor = FetchDescriptor<SkillMastery>()
        let masteries = (try? modelContext.fetch(skillDescriptor)) ?? []

        let vocabDescriptor = FetchDescriptor<ReviewItem>()
        let reviewItems = (try? modelContext.fetch(vocabDescriptor)) ?? []

        stats.totalSessions = sessions.count
        stats.totalMinutes = sessions.reduce(0) { $0 + $1.durationSeconds } / 60
        stats.wordsLearned = reviewItems.filter { $0.itemType.contains("vocab") && $0.correctCount > 0 }.count

        let skillTypes = ["Reading", "Listening", "Vocabulary", "Grammar", "Pronunciation"]
        let skillTypeKeys = ["reading", "listening", "vocab_recognition", "grammar", "pronunciation"]

        stats.skills = zip(skillTypes, skillTypeKeys).map { name, key in
            let matching = masteries.filter { $0.skillType == key }
            let avgAccuracy = matching.isEmpty ? 0.0 : matching.reduce(0.0) { $0 + $1.accuracy } / Double(matching.count)
            return SkillStat(name: name, mastery: avgAccuracy)
        }
    }
}

struct ProgressStats {
    var totalSessions: Int = 0
    var totalMinutes: Int = 0
    var wordsLearned: Int = 0
    var skills: [SkillStat] = []
}

struct SkillStat {
    let name: String
    let mastery: Double
}

struct MediaChallengeEntryView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MediaChallengeViewModel?

    var body: some View {
        Group {
            if let viewModel {
                MediaChallengeView(viewModel: viewModel)
            } else {
                ProgressView("Preparing challenge...")
            }
        }
        .onAppear {
            guard viewModel == nil else { return }
            let vm = MediaChallengeViewModel(
                claudeService: services.claude,
                learnerModel: services.learnerModel,
                userId: appState.currentUserId ?? UUID(),
                learnerLevel: appState.currentCEFRLevel.rawValue
            )
            let media = (try? modelContext.fetch(FetchDescriptor<MediaContent>())) ?? []
            vm.loadChallenge(availableContent: media)
            viewModel = vm
        }
    }
}
