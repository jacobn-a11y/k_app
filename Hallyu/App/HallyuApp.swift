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
    @State private var syncManager = OfflineSyncManager()

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
        let client = SupabaseClient()
        let result = await syncManager.syncAll(using: client)
        await MainActor.run {
            appState.pendingSyncCount = result.remaining
        }
    }
}
