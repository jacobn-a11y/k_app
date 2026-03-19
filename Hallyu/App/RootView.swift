import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                ContentView()
            } else {
                OnboardingView { result in
                    createProfileAndComplete(result: result)
                }
            }
        }
        .onAppear {
            _ = currentLearnerProfile(modelContext: modelContext, appState: appState)
        }
    }

    private func createProfileAndComplete(result: OnboardingResult) {
        let userId = appState.currentUserId
            ?? UserDefaults.standard.string(forKey: SessionPersistenceKeys.currentUserId)
                .flatMap(UUID.init(uuidString:))
            ?? UUID()

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
        persistLearnerSession(profile: profile, appState: appState)
        UserDefaults.standard.set(result.placedCEFRLevel ?? "pre-A1", forKey: SessionPersistenceKeys.currentCEFRLevel)
        UserDefaults.standard.set(true, forKey: SessionPersistenceKeys.onboardingComplete)
    }
}
