import Testing
import Foundation
@testable import HallyuCore

@Suite("OnboardingViewModel Tests")
struct OnboardingViewModelTests {

    // MARK: - Initial State

    @Test("ViewModel starts at welcome step")
    func initialState() {
        let vm = OnboardingViewModel()
        #expect(vm.currentStep == .welcome)
        #expect(vm.selectedMediaInterests.isEmpty)
        #expect(vm.selectedExperience == nil)
        #expect(vm.selectedGoal == .light)
        #expect(vm.isComplete == false)
        #expect(vm.shouldShowPlacementTest == false)
        #expect(vm.micDemoSkipped == false)
        #expect(vm.micDemoSucceeded == false)
    }

    // MARK: - Step Navigation

    @Test("Can always advance from welcome")
    func welcomeAlwaysAdvances() {
        let vm = OnboardingViewModel()
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .interests)
    }

    @Test("Cannot advance from interests without selecting at least one")
    func interestsRequiresSelection() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .interests)
        #expect(vm.canProceed == false)
        vm.selectedMediaInterests.insert(.drama)
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .proficiency)
    }

    @Test("Cannot advance from proficiency without selecting experience")
    func proficiencyRequiresSelection() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .proficiency)
        #expect(vm.canProceed == false)
        vm.selectedExperience = .none
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .dailyGoal)
    }

    @Test("Can always advance from daily goal")
    func dailyGoalAlwaysAdvances() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .dailyGoal)
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .micDemo)
    }

    @Test("Can always advance from mic demo (no hard gate)")
    func micDemoNoHardGate() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .micDemo)
        #expect(vm.canProceed == true)
    }

    @Test("goBack returns to previous step")
    func goBack() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .interests)
        #expect(vm.currentStep == .interests)
        vm.goBack()
        #expect(vm.currentStep == .welcome)
    }

    @Test("goBack from welcome does nothing")
    func goBackFromWelcome() {
        let vm = OnboardingViewModel()
        vm.goBack()
        #expect(vm.currentStep == .welcome)
    }

    // MARK: - Skip

    @Test("Can skip interests step")
    func skipInterests() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .interests)
        vm.skipCurrentStep()
        #expect(vm.currentStep == .proficiency)
    }

    @Test("Can skip proficiency step (defaults to none)")
    func skipProficiency() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .proficiency)
        vm.skipCurrentStep()
        #expect(vm.selectedExperience == .none)
        #expect(vm.currentStep == .dailyGoal)
    }

    @Test("Can skip mic demo step")
    func skipMicDemo() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .micDemo)
        vm.skipCurrentStep()
        #expect(vm.micDemoSkipped == true)
    }

    @Test("Cannot skip welcome or daily goal")
    func cannotSkipWelcomeOrGoal() {
        let vm = OnboardingViewModel()
        #expect(vm.canSkipCurrentStep == false)
        advanceTo(vm, step: .dailyGoal)
        #expect(vm.canSkipCurrentStep == false)
    }

    // MARK: - Progress

    @Test("Progress fraction increases with each step")
    func progressFraction() {
        let vm = OnboardingViewModel()
        let initial = vm.progressFraction
        #expect(initial > 0)

        advanceTo(vm, step: .interests)
        let interestsProgress = vm.progressFraction
        #expect(interestsProgress > initial)

        advanceTo(vm, step: .proficiency)
        #expect(vm.progressFraction > interestsProgress)
    }

    @Test("isFirstStep and isLastStep are correct")
    func firstLastStep() {
        let vm = OnboardingViewModel()
        #expect(vm.isFirstStep == true)
        #expect(vm.isLastStep == false)

        advanceTo(vm, step: .micDemo)
        #expect(vm.isFirstStep == false)
        #expect(vm.isLastStep == true)
    }

    // MARK: - Showcase

    @Test("Showcase snippets are populated with real content")
    func showcaseContent() {
        #expect(OnboardingViewModel.showcaseSnippets.count >= 8)
        let squidGame = OnboardingViewModel.showcaseSnippets.first { $0.source.contains("Squid Game") }
        #expect(squidGame != nil)
        #expect(squidGame?.korean == "무궁화 꽃이 피었습니다")

        let bts = OnboardingViewModel.showcaseSnippets.first { $0.source.contains("BTS") }
        #expect(bts != nil)
    }

    // MARK: - Mic Demo

    @Test("Mic demo starts in idle state")
    func micDemoInitialState() {
        let vm = OnboardingViewModel()
        #expect(vm.micDemoState == .idle)
        #expect(vm.micDemoIsRecording == false)
        #expect(vm.micDemoIsProcessing == false)
        #expect(vm.micDemoStatusIsSuccess == false)
        #expect(vm.micDemoStatusIsError == false)
    }

    @Test("Skip mic demo sets skipped flag")
    func skipMicDemoSetsFlag() {
        let vm = OnboardingViewModel()
        vm.skipMicDemo()
        #expect(vm.micDemoSkipped == true)
    }

    @Test("Reset mic demo clears state")
    func resetMicDemo() {
        let vm = OnboardingViewModel()
        vm.resetMicDemo()
        #expect(vm.micDemoTranscript == "")
        #expect(vm.micDemoConfidence == 0)
        #expect(vm.micDemoState == .idle)
    }

    // MARK: - Completion

    @Test("completeOnboarding returns correct result")
    func completeOnboarding() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests = [.drama, .music]
        vm.selectedExperience = .none
        vm.selectedGoal = .moderate

        let result = vm.completeOnboarding()
        #expect(result.mediaInterests.count == 2)
        #expect(result.experience == .none)
        #expect(result.dailyGoalMinutes == 20)
        #expect(result.needsPlacement == false)
        #expect(result.placedCEFRLevel == nil)
        #expect(vm.isComplete == true)
    }

    @Test("Selecting 'some' experience triggers placement on completion")
    func someExperienceTriggersPlacement() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests = [.drama]
        vm.selectedExperience = .some
        vm.selectedGoal = .light

        let result = vm.completeOnboarding()
        #expect(vm.shouldShowPlacementTest == true)
        #expect(result.needsPlacement == true)
    }

    @Test("completePlacementAndFinish returns level")
    func completePlacementAndFinish() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests = [.drama]
        vm.selectedExperience = .some
        vm.selectedGoal = .committed

        let result = vm.completePlacementAndFinish(cefrLevel: "A2")
        #expect(result.placedCEFRLevel == "A2")
        #expect(result.dailyGoalMinutes == 30)
        #expect(vm.isComplete == true)
    }

    @Test("dismissPlacementTest clears flag")
    func dismissPlacement() {
        let vm = OnboardingViewModel()
        vm.selectedExperience = .some
        _ = vm.completeOnboarding()
        #expect(vm.shouldShowPlacementTest == true)
        vm.dismissPlacementTest()
        #expect(vm.shouldShowPlacementTest == false)
    }

    // MARK: - Daily Goal

    @Test("Daily goal labels are correct")
    func dailyGoalLabels() {
        #expect(OnboardingViewModel.DailyGoal.light.label == "15 min")
        #expect(OnboardingViewModel.DailyGoal.moderate.label == "20 min")
        #expect(OnboardingViewModel.DailyGoal.committed.label == "30 min")
    }

    @Test("Default goal is light (15 min)")
    func defaultGoal() {
        let vm = OnboardingViewModel()
        #expect(vm.selectedGoal.rawValue == 15)
    }

    // MARK: - Analytics

    @Test("Step completion is tracked in analytics log")
    func analyticsTracking() {
        let vm = OnboardingViewModel()
        vm.advance() // welcome -> interests
        #expect(vm.analyticsLog.contains(.stepCompleted(.welcome)))
        #expect(vm.analyticsLog.contains(.stepViewed(.interests)))
    }

    @Test("Step skip is tracked in analytics log")
    func analyticsSkipTracking() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .interests)
        vm.skipCurrentStep()
        #expect(vm.analyticsLog.contains(.stepSkipped(.interests)))
    }

    @Test("Onboarding completion is tracked")
    func analyticsCompletion() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests = [.drama]
        vm.selectedExperience = .none
        _ = vm.completeOnboarding()
        let hasCompletion = vm.analyticsLog.contains(where: {
            if case .onboardingCompleted = $0 { return true }
            return false
        })
        #expect(hasCompletion == true)
    }

    // MARK: - Helpers

    private func advanceTo(_ vm: OnboardingViewModel, step: OnboardingViewModel.Step) {
        if vm.currentStep == .welcome && step.rawValue > OnboardingViewModel.Step.welcome.rawValue {
            vm.advance()
        }
        if vm.currentStep == .interests && step.rawValue > OnboardingViewModel.Step.interests.rawValue {
            vm.selectedMediaInterests.insert(.drama)
            vm.advance()
        }
        if vm.currentStep == .proficiency && step.rawValue > OnboardingViewModel.Step.proficiency.rawValue {
            vm.selectedExperience = .none
            vm.advance()
        }
        if vm.currentStep == .dailyGoal && step.rawValue > OnboardingViewModel.Step.dailyGoal.rawValue {
            vm.advance()
        }
    }
}
