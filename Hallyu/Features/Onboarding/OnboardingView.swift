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
                progressDots
                    .padding(.top, 8)

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
                    hookStep.tag(OnboardingViewModel.Step.hook)
                    promiseStep.tag(OnboardingViewModel.Step.promise)
                    firstSoundStep.tag(OnboardingViewModel.Step.firstSound)
                    firstConsonantStep.tag(OnboardingViewModel.Step.firstConsonant)
                    firstWordStep.tag(OnboardingViewModel.Step.firstWord)
                    previewExperienceStep.tag(OnboardingViewModel.Step.previewExperience)
                    journeyAheadStep.tag(OnboardingViewModel.Step.journeyAhead)
                    personalizeStep.tag(OnboardingViewModel.Step.personalize)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: viewModel.currentStep)

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
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.white : Color.white.opacity(0.15))
                    .frame(width: step == viewModel.currentStep ? 24 : 6, height: 3)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: viewModel.currentStep)
            }
        }
    }

    // MARK: - Step 1: Cinematic Hook

    private var hookStep: some View {
        ShowcaseHookView(viewModel: viewModel, reduceMotion: reduceMotion)
    }

    // MARK: - Step 2: Promise

    private var promiseStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                // Building blocks visual
                HStack(spacing: 12) {
                    jamoBlock("ㄱ")
                    Text("+").font(.title2).foregroundStyle(.white.opacity(0.25))
                    jamoBlock("ㅏ")
                    Text("=").font(.title2).foregroundStyle(.white.opacity(0.25))
                    jamoBlock("가", highlighted: true)
                }
                .opacity(viewModel.promiseAnimationPhase >= 1 ? 1 : 0.2)

                VStack(spacing: 16) {
                    Text("In 10 minutes, you'll\nread your first Korean word.")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Korean has an alphabet, just like English.\nEach letter is a building block.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()
        }
        .onAppear {
            guard viewModel.promiseAnimationPhase == 0 else { return }
            let delay: Double = reduceMotion ? 0 : 0.6
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5)) {
                    viewModel.advancePromiseAnimation()
                }
            }
        }
    }

    private func jamoBlock(_ character: String, highlighted: Bool = false) -> some View {
        Text(character)
            .font(.system(size: 36, weight: .medium))
            .foregroundStyle(highlighted ? .white : .white.opacity(0.8))
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(highlighted ? Color.blue.opacity(0.25) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(highlighted ? Color.blue.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
    }

    // MARK: - Step 3: First Sound (ㅏ)

    private var firstSoundStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("YOUR FIRST SOUND")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .tracking(3)

                Text(OnboardingViewModel.firstSoundCharacter)
                    .font(.system(size: 140, weight: .ultraLight))
                    .foregroundStyle(.white)

                Text("\"\(OnboardingViewModel.firstSoundLabel)\"")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(OnboardingViewModel.firstSoundHint)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            micCard
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Mic Card (shared)

    private var micCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                micStatusIcon
                Text(viewModel.firstLessonStatusMessage)
                    .font(.subheadline)
                    .foregroundStyle(micStatusTextColor)
                    .lineLimit(2)
            }

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
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: viewModel.firstLessonIsRecording ? "stop.circle.fill" : "mic.fill")
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
            .disabled(viewModel.firstLessonIsProcessing)

            if viewModel.firstLessonStatusIsSuccess {
                Label("You just spoke Korean.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(.green)
            } else if viewModel.firstLessonStatusIsError {
                Button("Try again") { viewModel.resetFirstLessonMicState() }
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
                            viewModel.firstLessonStatusIsSuccess ? Color.green.opacity(0.3) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.firstLessonMicState)
    }

    private var micButtonTitle: String {
        if viewModel.firstLessonIsRecording { return "Stop" }
        if viewModel.firstLessonStatusIsSuccess { return "Record again" }
        if viewModel.firstLessonStatusIsError { return "Try again" }
        return "Say it"
    }

    private var micButtonColor: Color {
        if viewModel.firstLessonIsRecording { return .red.opacity(0.8) }
        if viewModel.firstLessonStatusIsSuccess { return .green.opacity(0.7) }
        return .blue
    }

    @ViewBuilder
    private var micStatusIcon: some View {
        switch viewModel.firstLessonMicState {
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
        }
    }

    private var micStatusTextColor: Color {
        switch viewModel.firstLessonMicState {
        case .success: return .green
        case .error: return .orange
        default: return .white.opacity(0.45)
        }
    }

    // MARK: - Step 4: First Consonant (ㄱ)

    private var firstConsonantStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("NOW A CONSONANT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)
                    .tracking(3)

                Text(OnboardingViewModel.firstConsonantCharacter)
                    .font(.system(size: 140, weight: .ultraLight))
                    .foregroundStyle(.white)

                Text("\"\(OnboardingViewModel.firstConsonantLabel)\"")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(OnboardingViewModel.firstConsonantHint)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))

                // Mnemonic
                VStack(spacing: 6) {
                    Text("See the shape?")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("ㄱ looks like the letter G tilted forward")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 8)
            }

            Spacer()

            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                    viewModel.markConsonantLearned()
                }
                HapticManager.play(.light)
            } label: {
                Text(viewModel.hasLearnedConsonant ? "Got it" : "I see it — continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.hasLearnedConsonant ? Color.green.opacity(0.7) : Color.purple)
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

            VStack(spacing: 28) {
                Text("NOW COMBINE THEM")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)
                    .tracking(3)

                // Equation
                HStack(spacing: 14) {
                    jamoBlock(OnboardingViewModel.firstConsonantCharacter)
                    Text("+").font(.title2).foregroundStyle(.white.opacity(0.25))
                    jamoBlock(OnboardingViewModel.firstSoundCharacter)
                    Text("=").font(.title2).foregroundStyle(.white.opacity(0.25))

                    ZStack {
                        if viewModel.firstWordRevealed {
                            Text(OnboardingViewModel.firstWordCharacter)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("?")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                    }
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.firstWordRevealed ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        viewModel.firstWordRevealed ? Color.cyan.opacity(0.6) : Color.white.opacity(0.1),
                                        lineWidth: viewModel.firstWordRevealed ? 2 : 1
                                    )
                            )
                    )
                }

                if viewModel.firstWordRevealed {
                    VStack(spacing: 12) {
                        Text(OnboardingViewModel.firstWordCharacter)
                            .font(.system(size: 88, weight: .medium))
                            .foregroundStyle(.white)

                        Text("\"\(OnboardingViewModel.firstWordMeaning)\"")
                            .font(.title2)
                            .foregroundStyle(.cyan)

                        Text("You just read your first Korean word.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.top, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            if !viewModel.firstWordRevealed {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                        viewModel.revealFirstWord()
                    }
                    HapticManager.play(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.markFirstWordBuilt()
                    }
                } label: {
                    Text("Reveal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cyan)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Step 6: Preview Experience

    private var previewExperienceStep: some View {
        PreviewExperienceView(viewModel: viewModel, reduceMotion: reduceMotion)
    }

    // MARK: - Step 7: Journey Ahead

    private var journeyAheadStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 16)

                Text("Here's where this goes")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Timeline
                VStack(spacing: 0) {
                    ForEach(Array(OnboardingViewModel.journeyMilestones.enumerated()), id: \.element.id) { index, milestone in
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(index == 0 ? Color.green : Color.blue.opacity(0.5))
                                    .frame(width: 10, height: 10)
                                if index < OnboardingViewModel.journeyMilestones.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 1.5)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 10)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(milestone.timeframe.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                                    .tracking(1)
                                Text(milestone.headline)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                if let sample = milestone.sampleKorean {
                                    Text(sample)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.6))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                                }

                                Text(milestone.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            .padding(.bottom, 22)

                            Spacer()
                        }
                    }
                }

                // Media interest selection
                VStack(spacing: 14) {
                    Text("What do you want to understand?")
                        .font(.headline)
                        .foregroundStyle(.white)

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
                }
                .padding(.top, 4)

                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Step 8: Personalize

    private var personalizeStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 16)

                Text("Almost there")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Experience level
                VStack(alignment: .leading, spacing: 10) {
                    Text("Have you studied Korean before?")
                        .font(.headline)
                        .foregroundStyle(.white)

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
                            .padding(.vertical, 13)
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

                // Daily goal
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daily goal")
                        .font(.headline)
                        .foregroundStyle(.white)

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
                            .padding(.vertical, 13)
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
                        .foregroundStyle(.white.opacity(0.4))
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
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.canProceed)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.currentStep)
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

// MARK: - Cinematic Showcase Hook

/// Full-screen auto-cycling showcase of real Korean media content
private struct ShowcaseHookView: View {
    @Bindable var viewModel: OnboardingViewModel
    let reduceMotion: Bool

    @State private var snippetVisible = false
    @State private var englishVisible = false
    @State private var contextVisible = false
    @State private var autoTimer: Timer?
    @State private var cycleCount = 0

    var body: some View {
        ZStack {
            // Gradient background that shifts per category
            categoryGradient
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.0), value: viewModel.showcaseIndex)

            VStack(spacing: 0) {
                Spacer()

                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: snippet.category.iconName)
                    Text(snippet.category.rawValue)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .opacity(snippetVisible ? 1 : 0)

                Spacer().frame(height: 32)

                // Korean text — big, cinematic
                Text(snippet.korean)
                    .font(.system(size: koreanFontSize, weight: .thin))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(snippetVisible ? 1 : 0)
                    .scaleEffect(snippetVisible ? 1 : 0.95)

                Spacer().frame(height: 20)

                // English translation
                Text(snippet.english)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(englishVisible ? 1 : 0)

                Spacer().frame(height: 12)

                // Source + context
                VStack(spacing: 4) {
                    Text(snippet.source)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(snippet.contextNote)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.25))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }
                .opacity(contextVisible ? 1 : 0)

                Spacer()

                // Dot indicators for snippets
                HStack(spacing: 6) {
                    ForEach(0..<min(OnboardingViewModel.showcaseSnippets.count, 8), id: \.self) { i in
                        Circle()
                            .fill(i == viewModel.showcaseIndex % OnboardingViewModel.showcaseSnippets.count
                                  ? Color.white.opacity(0.8) : Color.white.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.bottom, 8)

                // CTA at bottom
                if viewModel.showcaseReady {
                    Text("This is what you'll understand.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
            }
        }
        .onAppear { startShowcaseLoop() }
        .onDisappear { autoTimer?.invalidate() }
    }

    private var snippet: OnboardingViewModel.ShowcaseSnippet {
        viewModel.currentShowcaseSnippet
    }

    private var koreanFontSize: CGFloat {
        snippet.korean.count <= 5 ? 72 : 40
    }

    private var categoryGradient: some View {
        let colors: [Color] = {
            switch snippet.category {
            case .drama: return [.purple.opacity(0.15), .black]
            case .music: return [.pink.opacity(0.12), .black]
            case .webtoon: return [.green.opacity(0.1), .black]
            case .viral: return [.orange.opacity(0.12), .black]
            case .news: return [.blue.opacity(0.1), .black]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private func startShowcaseLoop() {
        showCurrentSnippet()
        autoTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            Task { @MainActor in
                cycleCount += 1
                // After cycling through at least 3 snippets, mark ready
                if cycleCount >= 3 {
                    withAnimation { viewModel.markShowcaseReady() }
                }
                nextSnippet()
            }
        }
    }

    private func showCurrentSnippet() {
        snippetVisible = false
        englishVisible = false
        contextVisible = false

        let animate = !reduceMotion
        let d1: Double = animate ? 0.15 : 0
        let d2: Double = animate ? 0.8 : 0
        let d3: Double = animate ? 1.5 : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + d1) {
            withAnimation(animate ? .easeOut(duration: 0.5) : nil) { snippetVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d2) {
            withAnimation(animate ? .easeIn(duration: 0.4) : nil) { englishVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d3) {
            withAnimation(animate ? .easeIn(duration: 0.3) : nil) { contextVisible = true }
        }
    }

    private func nextSnippet() {
        let animate = !reduceMotion
        withAnimation(animate ? .easeIn(duration: 0.25) : nil) {
            snippetVisible = false
            englishVisible = false
            contextVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            viewModel.advanceShowcase()
            showCurrentSnippet()
        }
    }
}

// MARK: - Preview Experience (Mini-Demo)

/// Shows the user what the actual learning feed feels like
private struct PreviewExperienceView: View {
    @Bindable var viewModel: OnboardingViewModel
    let reduceMotion: Bool

    @State private var cardVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            Text("THIS IS WHAT LEARNING LOOKS LIKE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)

            Spacer()

            // Simulated feed card
            let card = viewModel.currentPreviewCard
            VStack(spacing: 20) {
                // Type badge
                Label(card.type.rawValue, systemImage: card.type.iconName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())

                // Korean text
                Text(card.korean)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)

                // English
                Text(card.english)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.55))

                // Description
                Text(card.detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(cardVisible ? 1 : 0)
            .offset(y: cardVisible ? 0 : 20)

            Spacer()

            // Card counter
            HStack(spacing: 8) {
                ForEach(0..<OnboardingViewModel.previewCards.count, id: \.self) { i in
                    Circle()
                        .fill(i == viewModel.previewCardIndex ? Color.white.opacity(0.8) : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 12)

            // Next card / "Got it" button
            Button {
                if viewModel.previewCardIndex < OnboardingViewModel.previewCards.count - 1 {
                    transitionToNextCard()
                } else {
                    viewModel.markPreviewSeen()
                }
                HapticManager.play(.light)
            } label: {
                Text(viewModel.previewSeen ? "Got it" :
                        viewModel.previewCardIndex < OnboardingViewModel.previewCards.count - 1 ? "Next" : "Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.12))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.2)) {
                cardVisible = true
            }
        }
    }

    private func transitionToNextCard() {
        let animate = !reduceMotion
        withAnimation(animate ? .easeIn(duration: 0.15) : nil) {
            cardVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            viewModel.advancePreviewCard()
            withAnimation(animate ? .easeOut(duration: 0.3) : nil) {
                cardVisible = true
            }
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
