import Testing
import Foundation
@testable import HallyuCore

@Suite("OnboardingViewModel Tests")
struct OnboardingViewModelTests {

    // MARK: - Initial State

    @Test("ViewModel starts at hook step")
    func initialState() {
        let vm = OnboardingViewModel()
        #expect(vm.currentStep == .hook)
        #expect(vm.selectedMediaInterests.isEmpty)
        #expect(vm.selectedExperience == nil)
        #expect(vm.selectedGoal == .light)
        #expect(vm.hasSpokenFirstJamo == false)
        #expect(vm.hasLearnedConsonant == false)
        #expect(vm.hasBuiltFirstWord == false)
        #expect(vm.isComplete == false)
        #expect(vm.shouldShowPlacementTest == false)
    }

    // MARK: - Step Navigation

    @Test("Cannot advance from hook until animation completes")
    func hookRequiresAnimation() {
        let vm = OnboardingViewModel()
        #expect(vm.canProceed == false)
        vm.advance()
        #expect(vm.currentStep == .hook)
    }

    @Test("Can advance from hook after animation phase 2")
    func hookAdvancesAfterAnimation() {
        let vm = OnboardingViewModel()
        vm.advanceHookAnimation() // phase 1
        vm.advanceHookAnimation() // phase 2
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .promise)
    }

    @Test("Can advance from promise after animation")
    func promiseAdvancesAfterAnimation() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .promise)
        #expect(vm.canProceed == false)
        vm.advancePromiseAnimation()
        #expect(vm.canProceed == true)
        vm.advance()
        #expect(vm.currentStep == .firstSound)
    }

    @Test("Cannot advance from firstSound without speaking jamo")
    func firstSoundRequiresJamo() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .firstSound)
        #expect(vm.canProceed == false)
        vm.markFirstJamoSpoken()
        #expect(vm.canProceed == true)
        #expect(vm.hasSpokenFirstJamo == true)
    }

    @Test("Cannot advance from firstConsonant without learning it")
    func firstConsonantRequiresLearning() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .firstConsonant)
        #expect(vm.canProceed == false)
        vm.markConsonantLearned()
        #expect(vm.canProceed == true)
    }

    @Test("Cannot advance from firstWord without building it")
    func firstWordRequiresBuilding() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .firstWord)
        #expect(vm.canProceed == false)
        vm.revealFirstWord()
        vm.markFirstWordBuilt()
        #expect(vm.canProceed == true)
    }

    @Test("Cannot advance from journeyAhead without selecting interests")
    func journeyAheadRequiresInterests() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .journeyAhead)
        #expect(vm.canProceed == false)
        vm.selectedMediaInterests.insert(.drama)
        #expect(vm.canProceed == true)
    }

    @Test("Cannot advance from personalize without selecting experience")
    func personalizeRequiresExperience() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .personalize)
        #expect(vm.canProceed == false)
        vm.selectedExperience = .none
        #expect(vm.canProceed == true)
    }

    @Test("Selecting 'some' experience triggers placement test")
    func someExperienceTriggerPlacement() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .personalize)
        vm.selectedExperience = .some
        vm.advance()
        #expect(vm.shouldShowPlacementTest == true)
        #expect(vm.currentStep == .personalize) // stays here while placement shows
    }

    @Test("goBack returns to previous step")
    func goBack() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .promise)
        #expect(vm.currentStep == .promise)
        vm.goBack()
        #expect(vm.currentStep == .hook)
    }

    @Test("goBack from hook does nothing")
    func goBackFromHook() {
        let vm = OnboardingViewModel()
        vm.goBack()
        #expect(vm.currentStep == .hook)
    }

    // MARK: - Progress

    @Test("Progress fraction increases with each step")
    func progressFraction() {
        let vm = OnboardingViewModel()
        #expect(vm.progressFraction > 0)

        advanceTo(vm, step: .promise)
        let promiseProgress = vm.progressFraction
        #expect(promiseProgress > 1.0 / 7.0)

        advanceTo(vm, step: .firstSound)
        #expect(vm.progressFraction > promiseProgress)
    }

    @Test("isFirstStep and isLastStep are correct")
    func firstLastStep() {
        let vm = OnboardingViewModel()
        #expect(vm.isFirstStep == true)
        #expect(vm.isLastStep == false)

        advanceTo(vm, step: .personalize)
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

    @Test("dismissPlacementTest clears flag")
    func dismissPlacement() {
        let vm = OnboardingViewModel()
        advanceTo(vm, step: .personalize)
        vm.selectedExperience = .some
        vm.advance() // triggers placement
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

    // MARK: - First Sound Mic State

    @Test("markFirstJamoSpoken sets success state")
    func markFirstJamoSpoken() {
        let vm = OnboardingViewModel()
        vm.markFirstJamoSpoken()
        #expect(vm.hasSpokenFirstJamo == true)
        #expect(vm.firstLessonStatusIsSuccess == true)
        #expect(vm.firstLessonConfidence == 1)
    }

    @Test("resetFirstLessonMicState clears state")
    func resetMicState() {
        let vm = OnboardingViewModel()
        vm.markFirstJamoSpoken()
        vm.resetFirstLessonMicState()
        #expect(vm.firstLessonTranscript == "")
        #expect(vm.firstLessonConfidence == 0)
        #expect(vm.firstLessonIsRecording == false)
    }

    // MARK: - First Word

    @Test("revealFirstWord and markFirstWordBuilt work together")
    func firstWordFlow() {
        let vm = OnboardingViewModel()
        #expect(vm.firstWordRevealed == false)
        #expect(vm.hasBuiltFirstWord == false)
        vm.revealFirstWord()
        #expect(vm.firstWordRevealed == true)
        vm.markFirstWordBuilt()
        #expect(vm.hasBuiltFirstWord == true)
    }

    // MARK: - Journey Milestones

    @Test("Journey milestones are populated")
    func journeyMilestones() {
        #expect(OnboardingViewModel.journeyMilestones.count == 5)
        #expect(OnboardingViewModel.journeyMilestones.first?.timeframe == "Today")
    }

    // MARK: - Helpers

    /// Advances the VM to a given step by satisfying all prerequisites
    private func advanceTo(_ vm: OnboardingViewModel, step: OnboardingViewModel.Step) {
        // Hook
        if vm.currentStep == .hook && step.rawValue > OnboardingViewModel.Step.hook.rawValue {
            vm.advanceHookAnimation()
            vm.advanceHookAnimation()
            vm.advance()
        }
        // Promise
        if vm.currentStep == .promise && step.rawValue > OnboardingViewModel.Step.promise.rawValue {
            vm.advancePromiseAnimation()
            vm.advance()
        }
        // First Sound
        if vm.currentStep == .firstSound && step.rawValue > OnboardingViewModel.Step.firstSound.rawValue {
            vm.markFirstJamoSpoken()
            vm.advance()
        }
        // First Consonant
        if vm.currentStep == .firstConsonant && step.rawValue > OnboardingViewModel.Step.firstConsonant.rawValue {
            vm.markConsonantLearned()
            vm.advance()
        }
        // First Word
        if vm.currentStep == .firstWord && step.rawValue > OnboardingViewModel.Step.firstWord.rawValue {
            vm.revealFirstWord()
            vm.markFirstWordBuilt()
            vm.advance()
        }
        // Journey Ahead
        if vm.currentStep == .journeyAhead && step.rawValue > OnboardingViewModel.Step.journeyAhead.rawValue {
            vm.selectedMediaInterests.insert(.drama)
            vm.advance()
        }
    }
}
