import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if appState.isOnboardingComplete {
            ContentView()
        } else {
            OnboardingView { result in
                createProfileAndComplete(result: result)
            }
        }
    }

    private func createProfileAndComplete(result: OnboardingResult) {
        let userId = appState.currentUserId ?? UUID()

        let profile = LearnerProfile(
            userId: userId,
            cefrLevel: result.placedCEFRLevel ?? "pre-A1",
            onboardingCompleted: true,
            dailyGoalMinutes: result.dailyGoalMinutes
        )

        // Skip Hangul if placed at A1 or above
        if let level = result.placedCEFRLevel,
           level != "pre-A1" {
            profile.hangulCompleted = true
        }

        modelContext.insert(profile)
        try? modelContext.save()

        // Update app state
        appState.isOnboardingComplete = true
        appState.dailyGoalMinutes = result.dailyGoalMinutes
        appState.currentUserId = userId
        if let level = result.placedCEFRLevel,
           let cefrLevel = AppState.CEFRLevel(rawValue: level) {
            appState.currentCEFRLevel = cefrLevel
        }

        // Persist onboarding completion
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
}
