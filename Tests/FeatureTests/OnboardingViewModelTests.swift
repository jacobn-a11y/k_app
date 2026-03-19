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
        #expect(vm.hasSpokenFirstJamo == false)
        #expect(vm.isComplete == false)
        #expect(vm.shouldShowPlacementTest == false)
    }

    // MARK: - Step Navigation

    @Test("Cannot advance from welcome without selecting media interests")
    func welcomeRequiresInterests() {
        let vm = OnboardingViewModel()
        #expect(vm.canProceed == false)
        vm.advance()
        #expect(vm.currentStep == .welcome) // Should not advance
    }

    @Test("Can advance from welcome after selecting interests")
    func welcomeAdvancesWithInterests() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.drama)
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .experience)
    }

    @Test("Cannot advance from experience without selecting option")
    func experienceRequiresSelection() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.music)
        vm.advance() // to experience
        #expect(vm.canProceed == false)
        vm.advance()
        #expect(vm.currentStep == .experience)
    }

    @Test("Selecting 'none' experience advances to goal setting")
    func noneExperienceAdvances() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.drama)
        vm.advance() // to experience
        vm.selectedExperience = .none
        vm.advance()
        #expect(vm.currentStep == .goalSetting)
    }

    @Test("Selecting 'some' experience triggers placement test")
    func someExperienceTriggerPlacement() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.drama)
        vm.advance() // to experience
        vm.selectedExperience = .some
        vm.advance()
        #expect(vm.shouldShowPlacementTest == true)
        #expect(vm.currentStep == .experience) // stays here while placement shows
    }

    @Test("Selecting 'hangulOnly' advances to goal setting")
    func hangulOnlyAdvances() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.webtoon)
        vm.advance()
        vm.selectedExperience = .hangulOnly
        vm.advance()
        #expect(vm.currentStep == .goalSetting)
    }

    @Test("Goal setting can always proceed")
    func goalSettingAlwaysProceeds() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.drama)
        vm.advance()
        vm.selectedExperience = .none
        vm.advance()
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .firstLesson)
    }

    @Test("First lesson requires spoken jamo")
    func firstLessonRequiresJamo() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.drama)
        vm.advance()
        vm.selectedExperience = .none
        vm.advance()
        vm.advance() // to firstLesson
        #expect(vm.canProceed == false)
        vm.markFirstJamoSpoken()
        #expect(vm.canProceed == true)
        #expect(vm.hasSpokenFirstJamo == true)
    }

    @Test("goBack returns to previous step")
    func goBack() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.drama)
        vm.advance()
        #expect(vm.currentStep == .experience)
        vm.goBack()
        #expect(vm.currentStep == .welcome)
    }

    @Test("goBack from welcome does nothing")
    func goBackFromWelcome() {
        let vm = OnboardingViewModel()
        vm.goBack()
        #expect(vm.currentStep == .welcome)
    }

    // MARK: - Progress

    @Test("Progress fraction increases with each step")
    func progressFraction() {
        let vm = OnboardingViewModel()
        let initial = vm.progressFraction
        #expect(initial == 0.25)

        vm.selectedMediaInterests.insert(.drama)
        vm.advance()
        #expect(vm.progressFraction == 0.5)

        vm.selectedExperience = .none
        vm.advance()
        #expect(vm.progressFraction == 0.75)

        vm.advance()
        #expect(vm.progressFraction == 1.0)
    }

    @Test("isFirstStep and isLastStep are correct")
    func firstLastStep() {
        let vm = OnboardingViewModel()
        #expect(vm.isFirstStep == true)
        #expect(vm.isLastStep == false)

        vm.selectedMediaInterests.insert(.drama)
        vm.advance()
        vm.selectedExperience = .none
        vm.advance()
        vm.advance()
        #expect(vm.isFirstStep == false)
        #expect(vm.isLastStep == true)
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

    @Test("dismissPlacementTest advances to next step")
    func dismissPlacement() {
        let vm = OnboardingViewModel()
        vm.selectedMediaInterests.insert(.drama)
        vm.advance() // experience
        vm.selectedExperience = .some
        vm.advance() // triggers placement
        #expect(vm.shouldShowPlacementTest == true)
        vm.dismissPlacementTest()
        #expect(vm.shouldShowPlacementTest == false)
        #expect(vm.currentStep == .goalSetting)
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
}
