import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = OnboardingViewModel()
    let onComplete: (OnboardingResult) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 8)
                    .padding(.horizontal, 24)

                TabView(selection: Binding(
                    get: { viewModel.currentStep },
                    set: { newStep in
                        if newStep.rawValue == viewModel.currentStep.rawValue + 1 && viewModel.canProceed {
                            viewModel.advance()
                        } else if newStep.rawValue == viewModel.currentStep.rawValue - 1 {
                            viewModel.goBack()
                        }
                    }
                )) {
                    welcomeStep.tag(OnboardingViewModel.Step.welcome)
                    interestsStep.tag(OnboardingViewModel.Step.interests)
                    proficiencyStep.tag(OnboardingViewModel.Step.proficiency)
                    dailyGoalStep.tag(OnboardingViewModel.Step.dailyGoal)
                    micDemoStep.tag(OnboardingViewModel.Step.micDemo)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: viewModel.currentStep)

                bottomNavigation
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.restoreProgress()
        }
        .sheet(isPresented: Binding(
            get: { viewModel.shouldShowPlacementTest },
            set: { if !$0 { viewModel.dismissPlacementTest() } }
        )) {
            PlacementTestView { cefrLevel in
                let result = viewModel.completePlacementAndFinish(cefrLevel: cefrLevel)
                onComplete(result)
            }
            .environment(services)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 3)

                Capsule()
                    .fill(Color.blue)
                    .frame(width: geo.size.width * viewModel.progressFraction, height: 3)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: viewModel.currentStep)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Single showcase snippet — static, no animation gate
                let snippet = viewModel.currentShowcaseSnippet
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: snippet.category.iconName)
                        Text(snippet.category.rawValue)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())

                    Text(snippet.korean)
                        .font(.system(size: snippet.korean.count <= 5 ? 64 : 36, weight: .thin))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(snippet.english)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))

                    Text("— \(snippet.source)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }

                VStack(spacing: 12) {
                    Text("Understand Korean media\nfor real.")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("We'll personalize your learning in under a minute.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()
        }
    }

    // MARK: - Step 2: Interests

    private var interestsStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("What do you want to understand?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Pick as many as you like")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(OnboardingViewModel.MediaInterest.allCases) { interest in
                    MediaInterestCard(
                        interest: interest,
                        isSelected: viewModel.selectedMediaInterests.contains(interest)
                    ) {
                        toggleInterest(interest)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 3: Proficiency

    private var proficiencyStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("Have you studied Korean before?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("This helps us start you at the right level")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            VStack(spacing: 10) {
                ForEach(OnboardingViewModel.KoreanExperience.allCases, id: \.rawValue) { exp in
                    Button {
                        viewModel.selectedExperience = exp
                    } label: {
                        HStack {
                            Text(exp.rawValue).font(.body)
                            Spacer()
                            if viewModel.selectedExperience == exp {
                                Image(systemName: "checkmark").fontWeight(.bold)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedExperience == exp ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.selectedExperience == exp ? Color.blue.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(viewModel.selectedExperience == exp ? .blue : .white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 24)

            if viewModel.selectedExperience == .some {
                Text("We'll give you a quick placement quiz after setup")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    // MARK: - Step 4: Daily Goal

    private var dailyGoalStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("Set your daily goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("You can change this anytime")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            VStack(spacing: 10) {
                ForEach(OnboardingViewModel.DailyGoal.allCases, id: \.rawValue) { goal in
                    Button {
                        viewModel.selectedGoal = goal
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(goal.label).font(.headline)
                                    Text("/ day").font(.subheadline).foregroundStyle(.white.opacity(0.35))
                                }
                                Text(goal.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            Spacer()
                            if viewModel.selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedGoal == goal ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.selectedGoal == goal ? Color.blue.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(viewModel.selectedGoal == goal ? .white : .white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 5: Mic Demo (Optional)

    private var micDemoStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("TRY YOUR VOICE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .tracking(3)

                Text(OnboardingViewModel.micDemoCharacter)
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundStyle(.white)

                Text("\"\(OnboardingViewModel.micDemoLabel)\"")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(OnboardingViewModel.micDemoHint)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            // Mic card or unavailable message
            if viewModel.micDemoIsUnavailable {
                unavailableMicCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            } else {
                micCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Mic Card

    private var micCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                micStatusIcon
                Text(viewModel.micDemoStatusMessage)
                    .font(.subheadline)
                    .foregroundStyle(micStatusTextColor)
                    .lineLimit(2)
            }

            Button {
                Task {
                    if viewModel.micDemoIsRecording {
                        await viewModel.stopMicDemo(
                            audioService: services.audio,
                            speechRecognition: services.speechRecognition
                        )
                    } else {
                        await viewModel.startMicDemo(
                            audioService: services.audio,
                            speechRecognition: services.speechRecognition
                        )
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.micDemoIsProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: viewModel.micDemoIsRecording ? "stop.circle.fill" : "mic.fill")
                    }
                    Text(micButtonTitle)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(micButtonColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.micDemoIsProcessing)

            if viewModel.micDemoStatusIsSuccess {
                Label("Nice! Voice is ready for lessons.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(.green)
            } else if viewModel.micDemoStatusIsError {
                Button("Try again") { viewModel.resetMicDemo() }
                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            viewModel.micDemoStatusIsSuccess ? Color.green.opacity(0.3) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.micDemoState)
    }

    private var unavailableMicCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.3))

            Text(viewModel.micDemoStatusMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Text("You can enable voice anytime in Settings.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var micButtonTitle: String {
        if viewModel.micDemoIsRecording { return "Stop" }
        if viewModel.micDemoStatusIsSuccess { return "Record again" }
        if viewModel.micDemoStatusIsError { return "Try again" }
        return "Say it"
    }

    private var micButtonColor: Color {
        if viewModel.micDemoIsRecording { return .red.opacity(0.8) }
        if viewModel.micDemoStatusIsSuccess { return .green.opacity(0.7) }
        return .blue
    }

    @ViewBuilder
    private var micStatusIcon: some View {
        switch viewModel.micDemoState {
        case .idle:
            Image(systemName: "mic.fill").foregroundStyle(.white.opacity(0.35))
        case .recording:
            Image(systemName: "waveform").foregroundStyle(.red)
                .symbolEffect(.pulse.byLayer, options: .repeating)
        case .processing:
            EmptyView()
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .error:
            Image(systemName: "arrow.counterclockwise").foregroundStyle(.orange)
        case .unavailable:
            Image(systemName: "mic.slash").foregroundStyle(.white.opacity(0.3))
        }
    }

    private var micStatusTextColor: Color {
        switch viewModel.micDemoState {
        case .success: return .green
        case .error: return .orange
        case .unavailable: return .white.opacity(0.4)
        default: return .white.opacity(0.45)
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        VStack(spacing: 8) {
            // Primary CTA — always visible, always works
            Button {
                if viewModel.isLastStep {
                    let result = viewModel.completeOnboarding()
                    onComplete(result)
                } else {
                    viewModel.advance()
                }
            } label: {
                Text(primaryCTALabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(viewModel.canProceed ? Color.blue : Color.blue.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.canProceed)
            .padding(.horizontal, 24)

            // Secondary row: Back + Skip
            HStack {
                if !viewModel.isFirstStep {
                    Button {
                        viewModel.goBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.semibold))
                            Text("Back")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Spacer()

                if viewModel.canSkipCurrentStep {
                    Button {
                        viewModel.skipCurrentStep()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 30)
        }
        .padding(.bottom, 16)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.currentStep)
    }

    private var primaryCTALabel: String {
        switch viewModel.currentStep {
        case .welcome:
            return "Get started"
        case .micDemo:
            if viewModel.micDemoSucceeded || viewModel.micDemoSkipped || viewModel.micDemoIsUnavailable {
                return "Start learning"
            }
            return "Start learning"
        default:
            return "Continue"
        }
    }

    // MARK: - Helpers

    private func toggleInterest(_ interest: OnboardingViewModel.MediaInterest) {
        if viewModel.selectedMediaInterests.contains(interest) {
            viewModel.selectedMediaInterests.remove(interest)
        } else {
            viewModel.selectedMediaInterests.insert(interest)
        }
        HapticManager.play(.light)
    }
}

// MARK: - Media Interest Card

struct MediaInterestCard: View {
    let interest: OnboardingViewModel.MediaInterest
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: interest.iconName)
                    .font(.title2)
                Text(interest.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? .blue : .white.opacity(0.6))
        }
    }
}
