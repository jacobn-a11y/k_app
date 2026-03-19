import SwiftUI
import SwiftData

struct DailyPlanView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DailyPlanViewModel?
    @State private var loadedProfile: LearnerProfile?
    @State private var loadedReviewItems: [ReviewItem] = []
    @State private var loadedMediaContent: [MediaContent] = []
    @State private var activeRoute: DailyPlanFlowRoute?
    @State private var activeActivityId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        ProgressView("Building your plan...")
                    } else if let plan = vm.plan {
                        planContent(plan: plan, viewModel: vm)
                    } else {
                        emptyPlanView
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Today")
            .onAppear { loadPlan() }
            .onChange(of: activeRoute?.id) { _, newRouteId in
                if newRouteId == nil {
                    activeActivityId = nil
                }
            }
            .sheet(item: $activeRoute) { route in
                DailyPlanActivityFlowSheet(
                    route: route,
                    services: services,
                    profile: loadedProfile
                ) {
                    finishActiveActivity(markAsComplete: true)
                }
            }
        }
    }

    // MARK: - Plan Content

    private func planContent(plan: DailyPlan, viewModel: DailyPlanViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection(viewModel: viewModel)
                progressSection(plan: plan)

                if viewModel.overdueReviewCount > 0 {
                    overdueReviewBanner(count: viewModel.overdueReviewCount)
                }

                activitiesSection(plan: plan)

                if plan.isComplete {
                    completionBanner
                }
            }
            .padding()
        }
    }

    // MARK: - Header

    private func headerSection(viewModel: DailyPlanViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.greeting)
                .font(.title2)
                .fontWeight(.semibold)

            if viewModel.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(viewModel.streak) day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Progress

    private func progressSection(plan: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(plan.completedMinutes) / \(plan.totalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(plan.completionProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            ProgressView(value: plan.completionProgress)
                .tint(plan.isComplete ? .green : .blue)
                .accessibilityLabel("Daily plan progress")
                .accessibilityValue("\(Int(plan.completionProgress * 100)) percent")
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Overdue Banner

    private func overdueReviewBanner(count: Int) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text("\(count) review item\(count == 1 ? "" : "s") overdue")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Activities

    private func activitiesSection(plan: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Plan")
                .font(.headline)

            ForEach(plan.activities) { activity in
                ActivityCardView(activity: activity) {
                    startActivity(activity)
                }
            }
        }
    }

    // MARK: - Completion Banner

    private var completionBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("All done for today!")
                .font(.headline)
            Text("Great work! See you tomorrow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyPlanView: some View {
        ContentUnavailableView(
            "No Plan Available",
            systemImage: "calendar.badge.plus",
            description: Text("Complete onboarding to get started.")
        )
    }

    // MARK: - Data Loading

    private func loadPlan() {
        let vm = DailyPlanViewModel(
            planGenerator: PlanGeneratorService(),
            srsEngine: services.srsEngine,
            learnerModel: services.learnerModel
        )

        guard let profile = currentLearnerProfile(modelContext: modelContext, appState: appState) else {
            viewModel = vm
            return
        }
        loadedProfile = profile

        let now = Date()
        let reviewDescriptor = FetchDescriptor<ReviewItem>()
        let reviewItems = (try? modelContext.fetch(reviewDescriptor)) ?? []
        loadedReviewItems = reviewItems.filter { $0.userId == profile.userId && $0.nextReviewAt <= now }

        let mediaDescriptor = FetchDescriptor<MediaContent>()
        let media = (try? modelContext.fetch(mediaDescriptor)) ?? []
        loadedMediaContent = media

        let skillDescriptor = FetchDescriptor<SkillMastery>()
        let skills = (try? modelContext.fetch(skillDescriptor)) ?? []

        let sessionDescriptor = FetchDescriptor<StudySession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        vm.loadPlan(
            profile: profile,
            reviewItems: reviewItems,
            mediaContent: media,
            skillMasteries: skills,
            studySessions: sessions
        )

        viewModel = vm
    }

    private func startActivity(_ activity: PlanActivity) {
        guard let profile = loadedProfile ?? currentLearnerProfile(modelContext: modelContext, appState: appState) else {
            return
        }

        activeActivityId = activity.id
        activeRoute = route(for: activity, profile: profile)
    }

    private func finishActiveActivity(markAsComplete: Bool) {
        guard let activeActivityId else { return }
        if markAsComplete {
            viewModel?.completeActivity(id: activeActivityId)
        }
        self.activeActivityId = nil
    }

    private func route(for activity: PlanActivity, profile: LearnerProfile) -> DailyPlanFlowRoute? {
        switch activity.type {
        case .srsReview:
            return .review(items: loadedReviewItems)
        case .mediaLesson:
            return .media(content: recommendedMediaContent(for: profile))
        case .hangulLesson:
            return .hangul(groupIndex: 0)
        case .pronunciationPractice:
            return .pronunciation(targetText: recommendedPronunciationTarget(for: profile))
        case .vocabularyBuilding:
            return .vocabulary
        case .grammarReview:
            return .grammar(
                pattern: recommendedGrammarPattern(for: profile),
                context: recommendedGrammarContext(for: profile)
            )
        }
    }

    private func recommendedMediaContent(for profile: LearnerProfile) -> MediaContent? {
        loadedMediaContent.first { $0.cefrLevel == profile.cefrLevel }
            ?? loadedMediaContent.first
    }

    private func recommendedPronunciationTarget(for profile: LearnerProfile) -> String {
        guard let media = recommendedMediaContent(for: profile) else {
            return "안녕하세요"
        }
        return KoreanTextAnalyzer.tokenize(media.transcriptKr).first ?? "안녕하세요"
    }

    private func recommendedGrammarPattern(for profile: LearnerProfile) -> String {
        switch profile.cefrLevel {
        case "pre-A1", "A1": return "-아/어요"
        case "A2": return "-고 싶다"
        case "B1": return "-(으)ㄴ데"
        default: return "-(으)ㄹ 수 있다"
        }
    }

    private func recommendedGrammarContext(for profile: LearnerProfile) -> String {
        recommendedMediaContent(for: profile)?.title ?? "Daily plan practice"
    }
}

// MARK: - Activity Card

struct ActivityCardView: View {
    let activity: PlanActivity
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(activity.isCompleted ? .green : iconColor)
                .frame(width: 36, height: 36)
                .background(
                    (activity.isCompleted ? Color.green : iconColor).opacity(0.1)
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(activity.isCompleted)
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(activity.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if activity.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Start") { onStart() }
                        .font(.caption)
                        .fontWeight(.medium)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Start \(activity.title)")
                        .accessibilityHint("Opens the activity flow for this task.")
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(activity.isCompleted ? 0.7 : 1.0)
    }

    private var iconName: String {
        switch activity.type {
        case .srsReview: return "arrow.counterclockwise"
        case .mediaLesson: return "play.rectangle.fill"
        case .hangulLesson: return "character.book.closed.fill"
        case .pronunciationPractice: return "waveform"
        case .vocabularyBuilding: return "text.book.closed.fill"
        case .grammarReview: return "list.bullet.rectangle.fill"
        }
    }

    private var iconColor: Color {
        switch activity.type {
        case .srsReview: return .orange
        case .mediaLesson: return .blue
        case .hangulLesson: return .purple
        case .pronunciationPractice: return .pink
        case .vocabularyBuilding: return .teal
        case .grammarReview: return .indigo
        }
    }
}

// MARK: - Activity Flow Sheet

private enum DailyPlanFlowRoute: Identifiable {
    case review(items: [ReviewItem])
    case media(content: MediaContent?)
    case hangul(groupIndex: Int)
    case pronunciation(targetText: String)
    case vocabulary
    case grammar(pattern: String, context: String)

    var id: String {
        switch self {
        case .review: return "review"
        case .media: return "media"
        case .hangul: return "hangul"
        case .pronunciation: return "pronunciation"
        case .vocabulary: return "vocabulary"
        case .grammar: return "grammar"
        }
    }
}

private struct DailyPlanActivityFlowSheet: View {
    let route: DailyPlanFlowRoute
    let services: ServiceContainer
    let profile: LearnerProfile?
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        routeView
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()

                    Button {
                        onComplete()
                        dismiss()
                    } label: {
                        Label("Finish Activity", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.regularMaterial)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .interactiveDismissDisabled(true)
    }

    @ViewBuilder
    private var routeView: some View {
        switch route {
        case .review(let items):
            ReviewSessionView(items: items, services: services)
        case .media(let content):
            if let content, let profile {
                MediaLessonView(
                    content: content,
                    userId: profile.userId,
                    learnerLevel: profile.cefrLevel,
                    services: services
                )
            } else {
                ContentUnavailableView(
                    "No Media Lesson Available",
                    systemImage: "play.rectangle.fill",
                    description: Text("Add media content to unlock this activity.")
                )
            }
        case .hangul(let groupIndex):
            HangulLessonView(groupIndex: groupIndex, services: services)
        case .pronunciation(let targetText):
            PronunciationPracticeFlowView(
                services: services,
                targetText: targetText
            )
        case .vocabulary:
            MediaLibraryView()
        case .grammar(let pattern, let context):
            GrammarReviewFlowView(
                services: services,
                pattern: pattern,
                context: context,
                userId: profile?.userId
            )
        }
    }
}

private struct PronunciationPracticeFlowView: View {
    @State private var viewModel: PronunciationTutorViewModel
    private let targetText: String

    init(services: ServiceContainer, targetText: String) {
        let viewModel = PronunciationTutorViewModel(
            claudeService: services.claude,
            audioService: services.audio,
            speechRecognition: services.speechRecognition,
            subscriptionTier: services.subscription.currentTier
        )
        _viewModel = State(initialValue: viewModel)
        self.targetText = targetText
    }

    var body: some View {
        PronunciationTutorView(viewModel: viewModel)
            .onAppear {
                if viewModel.targetText.isEmpty {
                    viewModel.setTarget(targetText)
                }
            }
    }
}

private struct GrammarReviewFlowView: View {
    @State private var viewModel: GrammarExplainerViewModel
    let userId: UUID?
    private let pattern: String
    private let context: String

    init(services: ServiceContainer, pattern: String, context: String, userId: UUID?) {
        let viewModel = GrammarExplainerViewModel(
            claudeService: services.claude,
            learnerModel: services.learnerModel,
            subscriptionTier: services.subscription.currentTier
        )
        _viewModel = State(initialValue: viewModel)
        self.userId = userId
        self.pattern = pattern
        self.context = context
    }

    var body: some View {
        if let userId {
            GrammarExplainerView(viewModel: viewModel, userId: userId)
                .onAppear {
                    if viewModel.pattern.isEmpty {
                        viewModel.presentGrammar(pattern: pattern, mediaContext: context)
                    }
                }
        } else {
            ContentUnavailableView(
                "Grammar Practice Unavailable",
                systemImage: "text.book.closed.fill",
                description: Text("Complete onboarding to access grammar practice.")
            )
        }
    }
}
