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
            // Dark background for immersive feel
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Subtle progress dots at top
                progressDots
                    .padding(.top, 8)

                // Step content
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
                    hookStep
                        .tag(OnboardingViewModel.Step.hook)
                    promiseStep
                        .tag(OnboardingViewModel.Step.promise)
                    firstSoundStep
                        .tag(OnboardingViewModel.Step.firstSound)
                    firstConsonantStep
                        .tag(OnboardingViewModel.Step.firstConsonant)
                    firstWordStep
                        .tag(OnboardingViewModel.Step.firstWord)
                    journeyAheadStep
                        .tag(OnboardingViewModel.Step.journeyAhead)
                    personalizeStep
                        .tag(OnboardingViewModel.Step.personalize)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: viewModel.currentStep)

                // Bottom navigation
                bottomNavigation
            }
        }
        .preferredColorScheme(.dark)
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

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.white : Color.white.opacity(0.2))
                    .frame(width: step == viewModel.currentStep ? 24 : 8, height: 4)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 1: Hook

    private var hookStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Korean text — large, cinematic
                Text(OnboardingViewModel.hookKoreanLine)
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(.white)
                    .opacity(viewModel.hookAnimationPhase >= 0 ? 1 : 0)

                // English translation fades in
                if viewModel.hookAnimationPhase >= 1 {
                    Text(OnboardingViewModel.hookEnglishLine)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Context line
                if viewModel.hookAnimationPhase >= 2 {
                    Text(OnboardingViewModel.hookContextLine)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }
            }

            Spacer()

            // "What if you could read it?" teaser
            if viewModel.hookAnimationPhase >= 2 {
                Text("What if you could actually read it?")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }
        }
        .onAppear {
            startHookAnimation()
        }
    }

    private func startHookAnimation() {
        guard viewModel.hookAnimationPhase == 0 else { return }
        let animate = !reduceMotion
        let delay1: Double = animate ? 1.5 : 0
        let delay2: Double = animate ? 3.0 : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay1) {
            withAnimation(animate ? .easeIn(duration: 0.8) : nil) {
                viewModel.advanceHookAnimation()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay2) {
            withAnimation(animate ? .easeIn(duration: 0.8) : nil) {
                viewModel.advanceHookAnimation()
            }
        }
    }

    // MARK: - Step 2: Promise

    private var promiseStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                // Building blocks visual
                HStack(spacing: 12) {
                    buildingBlock("ㄱ", delay: 0)
                    Text("+")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.3))
                    buildingBlock("ㅏ", delay: 0.2)
                    Text("=")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.3))
                    buildingBlock("가", delay: 0.4)
                }
                .opacity(viewModel.promiseAnimationPhase >= 1 ? 1 : 0.3)

                VStack(spacing: 16) {
                    Text(OnboardingViewModel.promiseTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(OnboardingViewModel.promiseSubtitle)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()
        }
        .onAppear {
            startPromiseAnimation()
        }
    }

    private func buildingBlock(_ character: String, delay: Double) -> some View {
        Text(character)
            .font(.system(size: 40, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }

    private func startPromiseAnimation() {
        guard viewModel.promiseAnimationPhase == 0 else { return }
        let animate = !reduceMotion
        DispatchQueue.main.asyncAfter(deadline: .now() + (animate ? 0.8 : 0)) {
            withAnimation(animate ? .easeOut(duration: 0.6) : nil) {
                viewModel.advancePromiseAnimation()
            }
        }
    }

    // MARK: - Step 3: First Sound (ㅏ)

    private var firstSoundStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("Your first Korean sound")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(2)

                // Large character display
                Text(OnboardingViewModel.firstSoundCharacter)
                    .font(.system(size: 140, weight: .ultraLight))
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)

                Text("This is \(OnboardingViewModel.firstSoundLabel)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(OnboardingViewModel.firstSoundHint)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Mic card
            micCard
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
    }

    private var micCard: some View {
        VStack(spacing: 16) {
            // Status
            HStack(spacing: 8) {
                micStatusIcon
                Text(viewModel.firstLessonStatusMessage)
                    .font(.subheadline)
                    .foregroundStyle(micStatusTextColor)
            }
            .padding(.horizontal)

            // Record button
            Button {
                Task {
                    if viewModel.firstLessonIsRecording {
                        await viewModel.stopFirstLessonRecording(
                            audioService: services.audio,
                            speechRecognition: services.speechRecognition
                        )
                    } else {
                        await viewModel.startFirstLessonRecording(
                            audioService: services.audio,
                            speechRecognition: services.speechRecognition
                        )
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.firstLessonIsProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: viewModel.firstLessonIsRecording ? "stop.circle.fill" : "mic.fill")
                    }
                    Text(micButtonTitle)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(micButtonColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.firstLessonIsProcessing)

            // Retry or success
            if viewModel.firstLessonStatusIsSuccess {
                Label("You just spoke Korean.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else if viewModel.firstLessonStatusIsError {
                Button("Try again") {
                    viewModel.resetFirstLessonMicState()
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            viewModel.firstLessonStatusIsSuccess
                                ? Color.green.opacity(0.3)
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .animation(reduceMotion ? nil : .easeInOut, value: viewModel.firstLessonMicState)
    }

    private var micButtonTitle: String {
        if viewModel.firstLessonIsRecording { return "Stop" }
        if viewModel.firstLessonStatusIsSuccess { return "Record again" }
        if viewModel.firstLessonStatusIsError { return "Try again" }
        return "Say it"
    }

    private var micButtonColor: Color {
        if viewModel.firstLessonIsRecording { return .red.opacity(0.8) }
        if viewModel.firstLessonStatusIsSuccess { return .green.opacity(0.8) }
        return .blue
    }

    @ViewBuilder
    private var micStatusIcon: some View {
        switch viewModel.firstLessonMicState {
        case .idle:
            Image(systemName: "mic.fill")
                .foregroundStyle(.white.opacity(0.4))
        case .recording:
            Image(systemName: "waveform")
                .foregroundStyle(.red)
                .symbolEffect(.pulse.byLayer, options: .repeating)
        case .processing:
            EmptyView()
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "arrow.counterclockwise")
                .foregroundStyle(.orange)
        }
    }

    private var micStatusTextColor: Color {
        switch viewModel.firstLessonMicState {
        case .success: return .green
        case .error: return .orange
        default: return .white.opacity(0.5)
        }
    }

    // MARK: - Step 4: First Consonant (ㄱ)

    private var firstConsonantStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("Now a consonant")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(2)

                Text(OnboardingViewModel.firstConsonantCharacter)
                    .font(.system(size: 140, weight: .ultraLight))
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)

                Text("This is \(OnboardingViewModel.firstConsonantLabel)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(OnboardingViewModel.firstConsonantHint)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))

                // Mnemonic visual
                VStack(spacing: 8) {
                    Text("See the shape?")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("ㄱ looks like the letter G tilted forward")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 8)
            }

            Spacer()

            // "Got it" button
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                    viewModel.markConsonantLearned()
                }
            } label: {
                Text(viewModel.hasLearnedConsonant ? "Got it" : "I see it — continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.hasLearnedConsonant ? Color.green.opacity(0.8) : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Step 5: First Word (가)

    private var firstWordStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Text("Now combine them")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(2)

                // Building blocks animation
                HStack(spacing: 16) {
                    Text(OnboardingViewModel.firstConsonantCharacter)
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 72, height: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    Text("+")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.3))

                    Text(OnboardingViewModel.firstSoundCharacter)
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 72, height: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    Text("=")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.3))

                    // Result — revealed
                    ZStack {
                        if viewModel.firstWordRevealed {
                            Text(OnboardingViewModel.firstWordCharacter)
                                .font(.system(size: 56, weight: .medium))
                                .foregroundStyle(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("?")
                                .font(.system(size: 56, weight: .light))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .frame(width: 72, height: 72)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.firstWordRevealed ? Color.blue.opacity(0.2) : .clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        viewModel.firstWordRevealed ? Color.blue.opacity(0.5) : Color.white.opacity(0.2),
                                        lineWidth: viewModel.firstWordRevealed ? 2 : 1
                                    )
                            )
                    )
                }

                if viewModel.firstWordRevealed {
                    VStack(spacing: 8) {
                        Text(OnboardingViewModel.firstWordCharacter)
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(.white)

                        Text("\"\(OnboardingViewModel.firstWordMeaning)\"")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        Text("You just read your first Korean word.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 8)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            // Reveal / Continue button
            if !viewModel.firstWordRevealed {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                        viewModel.revealFirstWord()
                    }
                    HapticManager.play(.success)
                    // Auto-mark after reveal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.markFirstWordBuilt()
                    }
                } label: {
                    Text("Reveal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Step 6: The Journey Ahead

    private var journeyAheadStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                Text("Here's where this goes")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Journey milestones
                VStack(spacing: 0) {
                    ForEach(Array(OnboardingViewModel.journeyMilestones.enumerated()), id: \.element.id) { index, milestone in
                        HStack(alignment: .top, spacing: 16) {
                            // Timeline
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(index == 0 ? Color.green : Color.blue.opacity(0.6))
                                    .frame(width: 12, height: 12)
                                if index < OnboardingViewModel.journeyMilestones.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 12)

                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                Text(milestone.timeframe)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                    .textCase(.uppercase)
                                Text(milestone.headline)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(milestone.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(.bottom, 24)

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 8)

                // Media interest selection
                VStack(spacing: 16) {
                    Text("What do you want to understand?")
                        .font(.headline)
                        .foregroundStyle(.white)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(OnboardingViewModel.MediaInterest.allCases) { interest in
                            MediaInterestCard(
                                interest: interest,
                                isSelected: viewModel.selectedMediaInterests.contains(interest)
                            ) {
                                toggleInterest(interest)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Step 7: Personalize

    private var personalizeStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                Text("Last thing — let's\npersonalize your path")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Experience level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Have you studied Korean before?")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach(OnboardingViewModel.KoreanExperience.allCases, id: \.rawValue) { exp in
                        Button {
                            viewModel.selectedExperience = exp
                        } label: {
                            HStack {
                                Text(exp.rawValue)
                                    .font(.body)
                                Spacer()
                                if viewModel.selectedExperience == exp {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedExperience == exp
                                          ? Color.blue.opacity(0.2)
                                          : Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                viewModel.selectedExperience == exp
                                                    ? Color.blue.opacity(0.5)
                                                    : Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundStyle(viewModel.selectedExperience == exp ? .blue : .white)
                        }
                    }
                }

                // Daily goal
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily goal")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach(OnboardingViewModel.DailyGoal.allCases, id: \.rawValue) { goal in
                        Button {
                            viewModel.selectedGoal = goal
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 8) {
                                        Text(goal.label)
                                            .font(.headline)
                                        Text("/ day")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    Text(goal.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                Spacer()
                                if viewModel.selectedGoal == goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedGoal == goal
                                          ? Color.blue.opacity(0.2)
                                          : Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                viewModel.selectedGoal == goal
                                                    ? Color.blue.opacity(0.5)
                                                    : Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundStyle(viewModel.selectedGoal == goal ? .white : .white.opacity(0.8))
                        }
                    }
                }

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack {
            if !viewModel.isFirstStep {
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 44, height: 44)
                }
            }

            Spacer()

            if viewModel.canProceed {
                Button {
                    if viewModel.isLastStep {
                        let result = viewModel.completeOnboarding()
                        onComplete(result)
                    } else {
                        viewModel.advance()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.isLastStep ? "Let's go" : "Continue")
                            .fontWeight(.semibold)
                        Image(systemName: viewModel.isLastStep ? "arrow.right" : "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.canProceed)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.currentStep)
    }

    // MARK: - Helpers

    private func toggleInterest(_ interest: OnboardingViewModel.MediaInterest) {
        if viewModel.selectedMediaInterests.contains(interest) {
            viewModel.selectedMediaInterests.remove(interest)
        } else {
            viewModel.selectedMediaInterests.insert(interest)
        }
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
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? .blue : .white.opacity(0.7))
        }
    }
}
