import SwiftUI
import SwiftData

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
                Tab("Today", systemImage: "play.circle.fill") {
                    LearningFeedView()
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
            SwiftDataContextRegistry.shared.modelContext = modelContext
            _ = currentLearnerProfile(modelContext: modelContext, appState: appState)
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
                .font(.system(size: 48))
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
        guard let profile = currentLearnerProfile(modelContext: modelContext, appState: appState) else {
            dueItems = []
            isLoading = false
            return
        }

        let descriptor = FetchDescriptor<ReviewItem>()
        let allItems = (try? modelContext.fetch(descriptor)) ?? []
        let userItems = allItems.filter { $0.userId == profile.userId }
        dueItems = services.srsEngine.getDueItems(for: profile.userId, from: userItems, limit: 20)
        isLoading = false
    }
}

// MARK: - Progress Tab (wired to ProgressDashboard)

struct ProgressTabView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var stats = ProgressStats()
    @State private var skillMasteries: [SkillMastery] = []
    @State private var availableMedia: [MediaContent] = []
    @State private var showingMonthlyChallenge = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    cefrLevelCard
                    entryPointsCard
                    studyStatsCard
                    skillBreakdownCard
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onAppear { loadStats() }
            .sheet(isPresented: $showingMonthlyChallenge) {
                if let profile = currentLearnerProfile(modelContext: modelContext, appState: appState) {
                    MonthlyChallengeSheetView(
                        services: services,
                        availableContent: availableMedia,
                        userId: profile.userId,
                        learnerLevel: profile.cefrLevel
                    )
                } else {
                    ContentUnavailableView(
                        "Monthly Challenge Unavailable",
                        systemImage: "trophy.fill",
                        description: Text("Complete onboarding to unlock the challenge.")
                    )
                }
            }
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
                .font(.system(size: 48, weight: .bold))
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

    private var entryPointsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Entries")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            NavigationLink {
                CEFRMilestoneView(
                    skillMasteries: skillMasteries,
                    currentLevel: appState.currentCEFRLevel.rawValue
                )
            } label: {
                entryPointRow(
                    icon: "flag.checkered",
                    title: "CEFR Milestones",
                    subtitle: "See the skills that unlock your next level"
                )
            }

            Button {
                showingMonthlyChallenge = true
            } label: {
                entryPointRow(
                    icon: "trophy.fill",
                    title: "Monthly Challenge",
                    subtitle: "Try an unscripted media challenge"
                )
            }
            .buttonStyle(.plain)
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
        guard let profile = currentLearnerProfile(modelContext: modelContext, appState: appState) else {
            stats = ProgressStats()
            skillMasteries = []
            availableMedia = []
            return
        }

        let sessionDescriptor = FetchDescriptor<StudySession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        let userSessions = sessions.filter { $0.userId == profile.userId }

        let skillDescriptor = FetchDescriptor<SkillMastery>()
        let masteries = (try? modelContext.fetch(skillDescriptor)) ?? []
        skillMasteries = masteries.filter { $0.userId == profile.userId }

        let vocabDescriptor = FetchDescriptor<ReviewItem>()
        let reviewItems = (try? modelContext.fetch(vocabDescriptor)) ?? []
        let userReviewItems = reviewItems.filter { $0.userId == profile.userId }

        let mediaDescriptor = FetchDescriptor<MediaContent>()
        availableMedia = (try? modelContext.fetch(mediaDescriptor)) ?? []

        stats.totalSessions = userSessions.count
        stats.totalMinutes = userSessions.reduce(0) { $0 + $1.durationSeconds } / 60
        stats.wordsLearned = userReviewItems.filter { $0.itemType.contains("vocab") && $0.correctCount > 0 }.count

        let skillTypes = ["Reading", "Listening", "Vocabulary", "Grammar", "Pronunciation"]
        let skillTypeKeys = ["reading", "listening", "vocab_recognition", "grammar", "pronunciation"]

        stats.skills = zip(skillTypes, skillTypeKeys).map { name, key in
            let matching = skillMasteries.filter { $0.skillType == key }
            let avgAccuracy = matching.isEmpty ? 0.0 : matching.reduce(0.0) { $0 + $1.accuracy } / Double(matching.count)
            return SkillStat(name: name, mastery: avgAccuracy)
        }
    }

    private func entryPointRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Progress Challenge Sheet

private struct MonthlyChallengeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MediaChallengeViewModel
    private let availableContent: [MediaContent]

    init(
        services: ServiceContainer,
        availableContent: [MediaContent],
        userId: UUID,
        learnerLevel: String
    ) {
        let viewModel = MediaChallengeViewModel(
            claudeService: services.claude,
            learnerModel: services.learnerModel,
            userId: userId,
            learnerLevel: learnerLevel
        )
        _viewModel = State(initialValue: viewModel)
        self.availableContent = availableContent
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MediaChallengeView(viewModel: viewModel)
                .onAppear {
                    if viewModel.challengeContent == nil {
                        viewModel.loadChallenge(availableContent: availableContent)
                    }
                }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}

// MARK: - Learner Session Restoration

enum SessionPersistenceKeys {
    static let onboardingComplete = "onboardingComplete"
    static let currentUserId = "currentUserId"
    static let currentCEFRLevel = "currentCEFRLevel"
    static let dailyGoalMinutes = "dailyGoalMinutes"
    static let placementResult = "placementTestResult"
}

@MainActor
func currentLearnerProfile(modelContext: ModelContext, appState: AppState) -> LearnerProfile? {
    let descriptor = FetchDescriptor<LearnerProfile>()
    let profiles = (try? modelContext.fetch(descriptor)) ?? []

    let storedUserId = UserDefaults.standard.string(forKey: SessionPersistenceKeys.currentUserId)
        .flatMap(UUID.init(uuidString:))
    let storedLevel = UserDefaults.standard.string(forKey: SessionPersistenceKeys.currentCEFRLevel)
        .flatMap(AppState.CEFRLevel.init(rawValue:))
    let storedPlacementLevel = UserDefaults.standard.string(forKey: SessionPersistenceKeys.placementResult)
        .flatMap(AppState.CEFRLevel.init(rawValue:))

    if let userId = appState.currentUserId ?? storedUserId,
       let profile = profiles.first(where: { $0.userId == userId }) {
        persistLearnerSession(profile: profile, appState: appState)
        return profile
    }

    if let profile = profiles.first {
        persistLearnerSession(profile: profile, appState: appState)
        return profile
    }

    if let storedUserId {
        appState.currentUserId = storedUserId
    }
    if let resolvedLevel = storedLevel ?? storedPlacementLevel {
        appState.currentCEFRLevel = resolvedLevel
    }
    if let storedGoal = UserDefaults.standard.object(forKey: SessionPersistenceKeys.dailyGoalMinutes) as? Int {
        appState.dailyGoalMinutes = storedGoal
    }
    appState.isOnboardingComplete = UserDefaults.standard.bool(forKey: SessionPersistenceKeys.onboardingComplete)

    return nil
}

@MainActor
func persistLearnerSession(profile: LearnerProfile, appState: AppState) {
    appState.currentUserId = profile.userId
    appState.currentCEFRLevel = AppState.CEFRLevel(rawValue: profile.cefrLevel) ?? appState.currentCEFRLevel
    appState.dailyGoalMinutes = profile.dailyGoalMinutes
    appState.isOnboardingComplete = profile.onboardingCompleted

    UserDefaults.standard.set(profile.userId.uuidString, forKey: SessionPersistenceKeys.currentUserId)
    UserDefaults.standard.set(profile.cefrLevel, forKey: SessionPersistenceKeys.currentCEFRLevel)
    UserDefaults.standard.set(profile.dailyGoalMinutes, forKey: SessionPersistenceKeys.dailyGoalMinutes)
    UserDefaults.standard.set(profile.onboardingCompleted, forKey: SessionPersistenceKeys.onboardingComplete)
}

final class SwiftDataContextRegistry {
    static let shared = SwiftDataContextRegistry()
    var modelContext: ModelContext?
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
