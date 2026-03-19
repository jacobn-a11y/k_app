import SwiftUI

struct MediaLessonView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: MediaLessonViewModel

    init(content: MediaContent, userId: UUID, learnerLevel: String, services: ServiceContainer) {
        _viewModel = State(initialValue: MediaLessonViewModel(
            content: content,
            claudeService: services.claude,
            srsEngine: services.srsEngine,
            learnerModel: services.learnerModel,
            audioService: services.audio,
            speechRecognition: services.speechRecognition,
            userId: userId,
            learnerLevel: learnerLevel
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            lessonProgressBar
            stepContent
        }
        .navigationTitle(viewModel.currentStep.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if viewModel.currentStepIndex > 0 && viewModel.currentStep != .summary {
                    Button("Back") {
                        withAnimation {
                            let prevIndex = viewModel.currentStepIndex - 1
                            if prevIndex >= 0 {
                                viewModel.goToStep(viewModel.availableSteps[prevIndex])
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.canAdvance && viewModel.currentStep != .summary {
                    Button("Next") {
                        withAnimation { viewModel.advanceToNextStep() }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Progress Bar

    private var lessonProgressBar: some View {
        VStack(spacing: 4) {
            // Step indicators
            HStack(spacing: 4) {
                ForEach(viewModel.availableSteps, id: \.rawValue) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stepColor(for: step))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)

            // Step info
            HStack {
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.totalSteps)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.currentStep.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private func stepColor(for step: MediaLessonViewModel.LessonStep) -> Color {
        if step == viewModel.currentStep {
            return .accentColor
        } else if step < viewModel.currentStep {
            return .accentColor.opacity(0.4)
        }
        return Color(.systemGray4)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .preTask:
            VocabularyPreTeachView(viewModel: viewModel)
        case .firstListen:
            firstListenView
        case .secondListen:
            secondListenView
        case .comprehensionCheck:
            ComprehensionCheckView(viewModel: viewModel)
        case .vocabularyExtraction:
            VocabularyExtractionView(viewModel: viewModel)
        case .shadowingPractice:
            ShadowingView(viewModel: viewModel)
        case .summary:
            LessonSummaryView(viewModel: viewModel)
        }
    }

    // MARK: - First Listen (No Subtitles)

    private var firstListenView: some View {
        VStack(spacing: 16) {
            Text("Listen carefully without subtitles")
                .font(.headline)
                .padding(.top)

            Text("Focus on what you can understand. Don't worry about catching everything.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Embedded media player with subtitles forced off
            MediaPlayerView(content: viewModel.content)
                .environment(\.subtitleModeOverride, .none)

            if !viewModel.firstListenCompleted {
                Button("I've finished listening") {
                    viewModel.completeFirstListen()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                Label("First listen complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding()
            }

            Spacer()
        }
    }

    // MARK: - Second Listen (Korean Subtitles)

    private var secondListenView: some View {
        VStack(spacing: 16) {
            Text("Listen again with Korean subtitles")
                .font(.headline)
                .padding(.top)

            Text("Tap any word you don't know to look it up.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            MediaPlayerView(content: viewModel.content)
                .environment(\.subtitleModeOverride, .koreanOnly)

            if !viewModel.secondListenCompleted {
                Button("I've finished listening") {
                    viewModel.completeSecondListen()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                Label("Second listen complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding()
            }

            Spacer()
        }
    }
}
