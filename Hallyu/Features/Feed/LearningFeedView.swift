import SwiftUI
import SwiftData

struct LearningFeedView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: LearningFeedViewModel?
    @State private var currentCardIndex: Int = 0

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    ProgressView("Loading your feed...")
                } else if vm.cards.isEmpty {
                    emptyFeedView
                } else {
                    feedContent(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear { loadFeed() }
    }

    // MARK: - Feed Content

    private func feedContent(vm: LearningFeedViewModel) -> some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(vm.cards.enumerated()), id: \.element.id) { index, card in
                        FeedCardContainerView(
                            card: card,
                            services: services,
                            onComplete: { score in
                                vm.completeCard(id: card.id, score: score)
                            },
                            onSkip: {
                                vm.skipCard(id: card.id)
                            }
                        )
                        .containerRelativeFrame(.vertical)
                        .id(card.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)

            // Overlay: XP counter, combo, progress, actions
            FeedOverlayView(
                totalXP: vm.totalXP,
                comboMultiplier: vm.comboMultiplier,
                goalProgress: vm.goalProgress,
                lastXPGain: vm.lastXPGain,
                showXPAnimation: vm.showXPAnimation,
                onDismissXP: { vm.dismissXPAnimation() },
                onShowPlan: { vm.showPlanSheet = true }
            )
        }
        .sheet(isPresented: Binding(
            get: { vm.showPlanSheet },
            set: { vm.showPlanSheet = $0 }
        )) {
            DailyPlanView()
                .overlay(alignment: .topTrailing) {
                    Button {
                        vm.showPlanSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
        }
    }

    // MARK: - Empty State

    private var emptyFeedView: some View {
        ContentUnavailableView(
            "No Content Available",
            systemImage: "play.rectangle.fill",
            description: Text("Complete onboarding to start your learning feed.")
        )
    }

    // MARK: - Data Loading

    private func loadFeed() {
        let vm = LearningFeedViewModel(
            srsEngine: services.srsEngine,
            learnerModel: services.learnerModel
        )

        guard let profile = currentLearnerProfile(modelContext: modelContext, appState: appState) else {
            viewModel = vm
            return
        }

        let reviewDescriptor = FetchDescriptor<ReviewItem>()
        let reviewItems = (try? modelContext.fetch(reviewDescriptor)) ?? []

        let mediaDescriptor = FetchDescriptor<MediaContent>()
        let media = (try? modelContext.fetch(mediaDescriptor)) ?? []

        let skillDescriptor = FetchDescriptor<SkillMastery>()
        let skills = (try? modelContext.fetch(skillDescriptor)) ?? []

        vm.loadFeed(
            profile: profile,
            reviewItems: reviewItems,
            mediaContent: media,
            skillMasteries: skills
        )

        viewModel = vm
    }
}

// MARK: - Card Container (routes to specific card views)

struct FeedCardContainerView: View {
    let card: FeedCard
    let services: ServiceContainer
    let onComplete: (Double?) -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            cardBackground

            VStack(spacing: 0) {
                Spacer()

                cardContent
                    .padding(.horizontal, 20)

                Spacer()

                if card.isInteractive && !card.isCompleted {
                    skipButton
                        .padding(.bottom, 80)
                }
            }

            if card.isCompleted {
                completedOverlay
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch card.content {
        case .jamoWatch(let jamo):
            JamoWatchFeedCard(jamo: jamo, onComplete: { onComplete(nil) })
        case .jamoTrace(let jamo):
            JamoTraceFeedCard(jamo: jamo, onComplete: { score in onComplete(score) })
        case .jamoSpeak(let jamo):
            JamoSpeakFeedCard(jamo: jamo, services: services, onComplete: { score in onComplete(score) })
        case .mediaClip(let info):
            MediaClipFeedCard(clipInfo: info, services: services, onComplete: { onComplete(nil) })
        case .vocab(let info):
            VocabFeedCard(info: info, onComplete: { correct in onComplete(correct ? 1.0 : 0.0) })
        case .pronunciation(let info):
            PronunciationFeedCard(info: info, services: services, onComplete: { score in onComplete(score) })
        case .grammarSnap(let info):
            GrammarFeedCard(info: info, onComplete: { correct in onComplete(correct ? 1.0 : 0.0) })
        case .goalReached(let xp, let count):
            GoalReachedCard(xpEarned: xp, cardsCompleted: count)
        }
    }

    private var cardBackground: some View {
        Group {
            switch card.content {
            case .mediaClip:
                Color.black.ignoresSafeArea()
            default:
                Color(.systemBackground).ignoresSafeArea()
            }
        }
    }

    private var skipButton: some View {
        Button {
            onSkip()
        } label: {
            Text("Skip")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel("Skip this card")
    }

    private var completedOverlay: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.green)
            .opacity(0.8)
            .transition(.scale.combined(with: .opacity))
            .allowsHitTesting(false)
    }
}
