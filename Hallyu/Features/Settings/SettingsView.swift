import SwiftUI

struct SettingsView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.isAuthenticated ? "Your Profile" : "Guest")
                                    .font(.headline)
                                Text(appState.currentCEFRLevel.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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

                    HStack {
                        Label("CEFR Level", systemImage: "chart.bar.fill")
                        Spacer()
                        Text(appState.currentCEFRLevel.rawValue)
                            .foregroundStyle(.secondary)
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
                    } else {
                        NavigationLink {
                            AuthView { session in
                                appState.isAuthenticated = true
                                appState.currentUserId = session.userId
                            }
                        } label: {
                            Label("Sign In", systemImage: "person.badge.plus")
                        }
                    }
                }

                // About section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
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
        isSigningOut = false
    }
}
