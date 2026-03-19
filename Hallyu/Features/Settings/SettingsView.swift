import SwiftUI

struct SettingsView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(NotificationService.self) private var notificationService
    @Environment(MediaDownloadManager.self) private var downloadManager
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.isAuthenticated ? "Your Profile" : "Guest")
                                    .font(.headline)
                                Text(appState.currentCEFRLevel.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(appState.isAuthenticated ? "Your Profile, level \(appState.currentCEFRLevel.rawValue)" : "Guest profile")
                    }
                }

                // Subscription section
                Section("Subscription") {
                    NavigationLink {
                        SubscriptionView(
                            currentTier: appState.subscriptionTier,
                            onTierChanged: { tier in
                                appState.subscriptionTier = tier
                            }
                        )
                    } label: {
                        HStack {
                            Label("Plan", systemImage: "crown.fill")
                            Spacer()
                            Text(tierDisplayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Subscription plan: \(tierDisplayName)")
                }

                // Learning section
                Section("Learning") {
                    HStack {
                        Label("Daily Goal", systemImage: "target")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { appState.dailyGoalMinutes },
                            set: { appState.dailyGoalMinutes = $0 }
                        )) {
                            Text("15 min").tag(15)
                            Text("20 min").tag(20)
                            Text("30 min").tag(30)
                        }
                        .pickerStyle(.menu)
                    }
                    .accessibilityLabel("Daily goal: \(appState.dailyGoalMinutes) minutes")

                    HStack {
                        Label("CEFR Level", systemImage: "chart.bar.fill")
                        Spacer()
                        Text(appState.currentCEFRLevel.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("CEFR level: \(appState.currentCEFRLevel.rawValue)")
                }

                // Notifications section
                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView(notificationService: notificationService)
                    } label: {
                        HStack {
                            Label("Review Reminders", systemImage: "bell.fill")
                            Spacer()
                            Text(notificationService.notificationsEnabled ? "On" : "Off")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Review reminders: \(notificationService.notificationsEnabled ? "On" : "Off")")
                }

                // Downloads section
                Section("Offline") {
                    NavigationLink {
                        DownloadsSettingsView(downloadManager: downloadManager)
                    } label: {
                        HStack {
                            Label("Downloads", systemImage: "arrow.down.circle.fill")
                            Spacer()
                            if downloadManager.downloadedMedia.isEmpty {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(downloadManager.downloadedMedia.count) items")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel("Downloads: \(downloadManager.downloadedMedia.count) items")
                }

                // Accessibility section
                Section("Accessibility") {
                    NavigationLink {
                        AccessibilitySettingsView()
                    } label: {
                        Label("Accessibility", systemImage: "accessibility")
                    }
                }

                // Account section
                Section("Account") {
                    if appState.isAuthenticated {
                        Button(role: .destructive) {
                            showSignOutConfirmation = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .disabled(isSigningOut)
                        .accessibilityHint("Sign out of your account")
                    } else {
                        NavigationLink {
                            AuthView { session in
                                appState.isAuthenticated = true
                                appState.currentUserId = session.userId
                            }
                        } label: {
                            Label("Sign In", systemImage: "person.badge.plus")
                        }
                        .accessibilityHint("Sign in to sync progress across devices")
                    }
                }

                // About section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(AppStoreMetadata.version)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Version \(AppStoreMetadata.version)")

                    Link(destination: URL(string: AppStoreMetadata.privacyPolicyURL)!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: AppStoreMetadata.termsOfServiceURL)!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Sign Out",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task { await signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your local progress will be preserved, but you'll need to sign in again to sync across devices.")
            }
        }
    }

    // MARK: - Helpers

    private var tierDisplayName: String {
        switch appState.subscriptionTier {
        case .free: return "Free"
        case .core: return "Core"
        case .pro: return "Pro"
        }
    }

    private func signOut() async {
        isSigningOut = true
        try? await services.auth.signOut()
        appState.isAuthenticated = false
        appState.currentUserId = nil
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        isSigningOut = false
    }
}
