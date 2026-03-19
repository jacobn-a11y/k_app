import SwiftUI
import SwiftData

struct DailyPlanView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DailyPlanViewModel?
    @State private var reviewRouteItems: [ReviewItem] = []
    @State private var showReviewRoute = false
    @State private var routeToMediaLesson: MediaContent?
    @State private var showHangulLesson = false
    @State private var showMediaLibrary = false
    @State private var activeActivityId: UUID?
    @State private var infoAlert: PlanInfoAlert?

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
            .navigationDestination(isPresented: $showReviewRoute) {
                ReviewSessionView(items: reviewRouteItems, services: services)
                    .onDisappear { markRoutedActivityComplete() }
            }
            .navigationDestination(item: $routeToMediaLesson) { content in
                MediaLessonView(
                    content: content,
                    userId: appState.currentUserId ?? UUID(),
                    learnerLevel: appState.currentCEFRLevel.rawValue,
                    services: services
                )
                .onDisappear { markRoutedActivityComplete() }
            }
            .navigationDestination(isPresented: $showHangulLesson) {
                HangulLessonView(groupIndex: 0, services: services)
                    .onDisappear { markRoutedActivityComplete() }
            }
            .navigationDestination(isPresented: $showMediaLibrary) {
                MediaLibraryView()
                    .onDisappear { markRoutedActivityComplete() }
            }
            .alert(item: $infoAlert) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
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

                activitiesSection(plan: plan, viewModel: viewModel)

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
        }
        .padding()
        .background(Color(.systemGray6))
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

    private func activitiesSection(plan: DailyPlan, viewModel: DailyPlanViewModel) -> some View {
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

        let fetchDescriptor = FetchDescriptor<LearnerProfile>()
        let profiles = (try? modelContext.fetch(fetchDescriptor)) ?? []
        guard let profile = profiles.first else {
            viewModel = vm
            return
        }

        if appState.currentUserId == nil {
            appState.currentUserId = profile.userId
        }
        if let level = AppState.CEFRLevel(rawValue: profile.cefrLevel) {
            appState.currentCEFRLevel = level
        }

        let now = Date()
        let reviewDescriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate { $0.nextReviewAt <= now }
        )
        let reviewItems = (try? modelContext.fetch(reviewDescriptor)) ?? []

        let mediaDescriptor = FetchDescriptor<MediaContent>()
        let media = (try? modelContext.fetch(mediaDescriptor)) ?? []

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
        switch activity.type {
        case .srsReview:
            let descriptor = FetchDescriptor<ReviewItem>()
            let allItems = (try? modelContext.fetch(descriptor)) ?? []
            guard let userId = appState.currentUserId ?? allItems.first?.userId else {
                infoAlert = PlanInfoAlert(
                    title: "No Review Items",
                    message: "Complete a lesson first so we can build your review queue."
                )
                return
            }
            let dueItems = services.srsEngine.getDueItems(for: userId, from: allItems, limit: max(10, activity.reviewItemCount))
            guard !dueItems.isEmpty else {
                infoAlert = PlanInfoAlert(
                    title: "Review Queue Empty",
                    message: "You’re all caught up. Start a lesson to add new review items."
                )
                return
            }
            activeActivityId = activity.id
            reviewRouteItems = dueItems
            showReviewRoute = true

        case .mediaLesson:
            guard let mediaId = activity.mediaContentId else {
                infoAlert = PlanInfoAlert(
                    title: "Media Not Available",
                    message: "This activity has no linked media yet."
                )
                return
            }
            let allMedia = (try? modelContext.fetch(FetchDescriptor<MediaContent>())) ?? []
            guard let content = allMedia.first(where: { $0.id == mediaId }) else {
                infoAlert = PlanInfoAlert(
                    title: "Media Not Found",
                    message: "Refresh your plan and try again."
                )
                return
            }
            activeActivityId = activity.id
            routeToMediaLesson = content

        case .hangulLesson:
            activeActivityId = activity.id
            showHangulLesson = true

        case .pronunciationPractice, .vocabularyBuilding, .grammarReview:
            activeActivityId = activity.id
            showMediaLibrary = true
        }
    }

    private func markRoutedActivityComplete() {
        guard let id = activeActivityId, let viewModel else { return }
        viewModel.completeActivity(id: id)
        activeActivityId = nil
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
                        .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
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

struct PlanInfoAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
