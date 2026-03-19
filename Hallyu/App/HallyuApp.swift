import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@main
struct HallyuApp: App {
    let modelContainer: ModelContainer
    @State private var serviceContainer: ServiceContainer
    @State private var appState: AppState
    @State private var networkMonitor: NetworkMonitor
    @State private var notificationService: NotificationService
    @State private var downloadManager: MediaDownloadManager
    @State private var supabaseClient = SupabaseClient()
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(PushNotificationAppDelegate.self) private var pushNotificationDelegate
    #endif

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
        state.isOnboardingComplete = UserDefaults.standard.bool(forKey: SessionPersistenceKeys.onboardingComplete)
        if let userId = UserDefaults.standard.string(forKey: SessionPersistenceKeys.currentUserId)
            .flatMap(UUID.init(uuidString:)) {
            state.currentUserId = userId
        }
        if let level = UserDefaults.standard.string(forKey: SessionPersistenceKeys.currentCEFRLevel),
           let cefr = AppState.CEFRLevel(rawValue: level) {
            state.currentCEFRLevel = cefr
        }
        if let goal = UserDefaults.standard.object(forKey: SessionPersistenceKeys.dailyGoalMinutes) as? Int {
            state.dailyGoalMinutes = goal
        }

        hydrateState(state, using: container)

        state.isAuthenticated = container.auth.isAuthenticated
        state.subscriptionTier = container.subscription.currentTier
        if let sessionUserId = container.auth.currentSession?.userId {
            state.currentUserId = sessionUserId
        }
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
                .onChange(of: appState.currentUserId) { _, _ in
                    Task { await notificationService.refreshPushRegistration() }
                }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Setup

    private func setupNetworkMonitoring() {
        networkMonitor.start()
    }

    private func setupNotifications() {
        notificationService.configurePushRegistrationHandler { payload in
            await supabaseClient.setAccessToken(serviceContainer.auth.currentSession?.accessToken)
            try await supabaseClient.registerPushToken(
                deviceToken: payload.deviceToken,
                userId: appState.currentUserId ?? serviceContainer.auth.currentSession?.userId,
                notificationsEnabled: payload.notificationsEnabled,
                reminderHour: payload.reminderHour,
                reminderMinute: payload.reminderMinute
            )
        }

        notificationService.registerCategories()
        Task {
            await notificationService.checkAuthorizationStatus()
            await notificationService.refreshPushRegistration()
        }
    }

    private func syncPendingOperations() async {
        guard let token = serviceContainer.auth.currentSession?.accessToken,
              !token.isEmpty else {
            await refreshPendingSyncCount()
            return
        }

        await supabaseClient.setAccessToken(token)
        let result = await serviceContainer.syncManager.syncAll(using: supabaseClient)
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

        state.subscriptionTier = services.subscription.currentTier
    }
}
