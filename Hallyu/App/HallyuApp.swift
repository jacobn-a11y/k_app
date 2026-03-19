import SwiftUI
import SwiftData

@main
struct HallyuApp: App {
    let modelContainer: ModelContainer
    @State private var serviceContainer: ServiceContainer
    @State private var appState: AppState

    init() {
        let schema = Schema([
            LearnerProfile.self,
            VocabularyItem.self,
            GrammarPattern.self,
            MediaContent.self,
            ReviewItem.self,
            SkillMastery.self,
            StudySession.self,
            ClaudeInteraction.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let container = ServiceContainer()
        _serviceContainer = State(initialValue: container)

        let state = AppState()
        // Restore persisted onboarding state
        state.isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        _appState = State(initialValue: state)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(serviceContainer)
                .environment(appState)
        }
        .modelContainer(modelContainer)
    }
}
