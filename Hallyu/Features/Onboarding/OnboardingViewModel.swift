import Foundation
import Observation

@Observable
final class OnboardingViewModel {

    // MARK: - Types

    enum Step: Int, CaseIterable {
        case welcome = 0
        case experience
        case goalSetting
        case firstLesson
    }

    enum KoreanExperience: String, CaseIterable {
        case none = "No, I'm starting fresh"
        case some = "I know some Korean"
        case hangulOnly = "I can read Hangul but that's it"
    }

    enum MediaInterest: String, CaseIterable, Identifiable {
        case drama = "K-Dramas"
        case music = "K-Pop"
        case webtoon = "Webtoons"
        case news = "News"
        case variety = "Variety Shows"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .drama: return "play.rectangle.fill"
            case .music: return "music.note"
            case .webtoon: return "book.fill"
            case .news: return "newspaper.fill"
            case .variety: return "tv.fill"
            }
        }
    }

    enum DailyGoal: Int, CaseIterable {
        case light = 15
        case moderate = 20
        case committed = 30

        var label: String {
            switch self {
            case .light: return "15 min"
            case .moderate: return "20 min"
            case .committed: return "30 min"
            }
        }

        var description: String {
            switch self {
            case .light: return "Light"
            case .moderate: return "Moderate"
            case .committed: return "Committed"
            }
        }
    }

    // MARK: - State

    private(set) var currentStep: Step = .welcome
    var selectedMediaInterests: Set<MediaInterest> = []
    var selectedExperience: KoreanExperience?
    var selectedGoal: DailyGoal = .light
    private(set) var hasSpokenFirstJamo: Bool = false
    private(set) var isComplete: Bool = false
    private(set) var shouldShowPlacementTest: Bool = false
    private(set) var placedCEFRLevel: String?

    // MARK: - Computed

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return !selectedMediaInterests.isEmpty
        case .experience:
            return selectedExperience != nil
        case .goalSetting:
            return true
        case .firstLesson:
            return hasSpokenFirstJamo
        }
    }

    var isFirstStep: Bool {
        currentStep == .welcome
    }

    var isLastStep: Bool {
        currentStep == .firstLesson
    }

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    // MARK: - Actions

    func advance() {
        guard canProceed else { return }

        if currentStep == .experience, selectedExperience == .some {
            shouldShowPlacementTest = true
            return
        }

        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func goBack() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    func markFirstJamoSpoken() {
        hasSpokenFirstJamo = true
    }

    func completeOnboarding() -> OnboardingResult {
        isComplete = true
        return OnboardingResult(
            mediaInterests: Array(selectedMediaInterests),
            experience: selectedExperience ?? .none,
            dailyGoalMinutes: selectedGoal.rawValue,
            needsPlacement: shouldShowPlacementTest,
            placedCEFRLevel: placedCEFRLevel
        )
    }

    func applyPlacementResult(cefrLevel: String) {
        placedCEFRLevel = cefrLevel
        shouldShowPlacementTest = false
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func dismissPlacementTest() {
        shouldShowPlacementTest = false
        if currentStep == .experience,
           let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }
}

// MARK: - Result

struct OnboardingResult {
    let mediaInterests: [OnboardingViewModel.MediaInterest]
    let experience: OnboardingViewModel.KoreanExperience
    let dailyGoalMinutes: Int
    let needsPlacement: Bool
    var placedCEFRLevel: String? = nil
}
