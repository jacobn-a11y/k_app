import SwiftUI
import SwiftData

struct DailyPlanView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DailyPlanViewModel?

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
                    viewModel.completeActivity(id: activity.id)
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
}

// MARK: - Activity Card

struct ActivityCardView: View {
    let activity: PlanActivity
    let onComplete: () -> Void

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
                    Button("Start") { onComplete() }
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
