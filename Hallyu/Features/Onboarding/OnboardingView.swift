import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = OnboardingViewModel()
    let onComplete: (OnboardingResult) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: viewModel.progressFraction)
                .tint(.blue)
                .padding(.horizontal)

            // Step content
            TabView(selection: Binding(
                get: { viewModel.currentStep },
                set: { newStep in
                    // Allow swiping only to adjacent steps
                    if newStep.rawValue == viewModel.currentStep.rawValue + 1 && viewModel.canProceed {
                        viewModel.advance()
                    } else if newStep.rawValue == viewModel.currentStep.rawValue - 1 {
                        viewModel.goBack()
                    }
                }
            )) {
                welcomeStep
                    .tag(OnboardingViewModel.Step.welcome)
                experienceStep
                    .tag(OnboardingViewModel.Step.experience)
                goalSettingStep
                    .tag(OnboardingViewModel.Step.goalSetting)
                firstLessonStep
                    .tag(OnboardingViewModel.Step.firstLesson)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut, value: viewModel.currentStep)

            // Navigation buttons
            navigationButtons
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

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Text("Learn Korean through\nthe media you love")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("What do you want to understand?")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(OnboardingViewModel.MediaInterest.allCases) { interest in
                        MediaInterestCard(
                            interest: interest,
                            isSelected: viewModel.selectedMediaInterests.contains(interest)
                        ) {
                            toggleInterest(interest)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }

    // MARK: - Step 2: Experience

    private var experienceStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Have you studied\nKorean before?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(OnboardingViewModel.KoreanExperience.allCases, id: \.rawValue) { exp in
                    Button {
                        viewModel.selectedExperience = exp
                    } label: {
                        Text(exp.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                viewModel.selectedExperience == exp
                                    ? Color.blue.opacity(0.15)
                                    : Color(.systemGray6)
                            )
                            .foregroundStyle(
                                viewModel.selectedExperience == exp ? .blue : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        viewModel.selectedExperience == exp ? Color.blue : .clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Step 3: Goal Setting

    private var goalSettingStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Set your daily goal")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("How much time can you commit each day?")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(OnboardingViewModel.DailyGoal.allCases, id: \.rawValue) { goal in
                    Button {
                        viewModel.selectedGoal = goal
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.description)
                                    .font(.headline)
                                Text(goal.label)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(
                            viewModel.selectedGoal == goal
                                ? Color.blue.opacity(0.15)
                                : Color(.systemGray6)
                        )
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.selectedGoal == goal ? Color.blue : .clear,
                                    lineWidth: 2
                                )
                        )
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Step 4: First Lesson

    private var firstLessonStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("\u{314F}")
                .scaledFont(size: 120, weight: .regular)
                .padding()

            Text("This is \u{314F} (ah)")
                .font(.title)
                .fontWeight(.bold)

            Text("It sounds like the 'a' in 'father'")
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
                viewModel.markFirstJamoSpoken()
            } label: {
                HStack {
                    Image(systemName: viewModel.hasSpokenFirstJamo ? "checkmark.circle.fill" : "mic.fill")
                    Text(viewModel.hasSpokenFirstJamo ? "You just spoke Korean!" : "Tap to pronounce")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.hasSpokenFirstJamo ? Color.green : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            if viewModel.hasSpokenFirstJamo {
                Text("Amazing! Let's keep going.")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }

            Spacer()
        }
        .animation(reduceMotion ? nil : .easeInOut, value: viewModel.hasSpokenFirstJamo)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            if !viewModel.isFirstStep {
                Button("Back") {
                    viewModel.goBack()
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.isLastStep {
                Button {
                    let result = viewModel.completeOnboarding()
                    onComplete(result)
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                }
                .disabled(!viewModel.canProceed)
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    viewModel.advance()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                }
                .disabled(!viewModel.canProceed)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .padding(.bottom, 8)
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
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : .clear, lineWidth: 2)
            )
        }
    }
}
