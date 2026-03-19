import SwiftUI
import SwiftData

@main
struct HallyuApp: App {
    let modelContainer: ModelContainer
    @State private var serviceContainer: ServiceContainer
    @State private var appState: AppState
    @State private var networkMonitor: NetworkMonitor
    @State private var notificationService: NotificationService
    @State private var downloadManager: MediaDownloadManager

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

        if let container = try? ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        ) {
            modelContainer = container
        } else {
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            if let fallbackContainer = try? ModelContainer(
                for: schema,
                configurations: [fallbackConfiguration]
            ) {
                print("[HallyuApp] Failed to initialize persistent ModelContainer. Falling back to in-memory store.")
                modelContainer = fallbackContainer
            } else {
                preconditionFailure("Could not create any ModelContainer configuration.")
            }
        }

        let container = ServiceContainer()
        _serviceContainer = State(initialValue: container)

        let state = AppState()
        // Restore persisted onboarding state
        state.isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        hydrateState(state, using: container)
        _appState = State(initialValue: state)

        let monitor = NetworkMonitor()
        _networkMonitor = State(initialValue: monitor)

        let notifications = NotificationService()
        _notificationService = State(initialValue: notifications)

        let downloads = MediaDownloadManager()
        _downloadManager = State(initialValue: downloads)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(serviceContainer)
                .environment(appState)
                .environment(networkMonitor)
                .environment(notificationService)
                .environment(downloadManager)
                .onAppear {
                    setupNetworkMonitoring()
                    setupNotifications()
                    Task { await refreshPendingSyncCount() }
                }
                .onChange(of: networkMonitor.isConnected) { _, isConnected in
                    appState.isOffline = !isConnected
                    if isConnected {
                        Task { await syncPendingOperations() }
                    }
                }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Setup

    private func setupNetworkMonitoring() {
        networkMonitor.start()
    }

    private func setupNotifications() {
        notificationService.registerCategories()
        Task {
            await notificationService.checkAuthorizationStatus()
        }
    }

    private func syncPendingOperations() async {
        guard let token = serviceContainer.auth.currentSession?.accessToken,
              !token.isEmpty else {
            await refreshPendingSyncCount()
            return
        }

        let client = SupabaseClient()
        await client.setAccessToken(token)

        let result = await serviceContainer.syncManager.syncAll(using: client)
        await MainActor.run {
            appState.pendingSyncCount = result.remaining
        }
    }

    private func refreshPendingSyncCount() async {
        let pendingCount = await serviceContainer.syncManager.pendingCount
        await MainActor.run {
            appState.pendingSyncCount = pendingCount
        }
    }

    private func hydrateState(_ state: AppState, using services: ServiceContainer) {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<LearnerProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []

        if let profile = profiles.first {
            state.currentUserId = profile.userId
            state.dailyGoalMinutes = profile.dailyGoalMinutes
            state.subscriptionTier = profile.subscriptionTierEnum
            state.isOnboardingComplete = state.isOnboardingComplete || profile.onboardingCompleted
            if let level = AppState.CEFRLevel(rawValue: profile.cefrLevel) {
                state.currentCEFRLevel = level
            }
        }

        if let session = services.auth.currentSession {
            state.isAuthenticated = true
            state.currentUserId = session.userId
        }

        // Always trust entitlement service for active tier at launch.
        state.subscriptionTier = services.subscription.currentTier
    }
}
