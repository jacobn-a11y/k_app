import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var profile: LearnerProfile?

    var body: some View {
        List {
            Section("Learning Profile") {
                profileRow(label: "CEFR Level", value: profile?.cefrLevel ?? appState.currentCEFRLevel.rawValue)
                profileRow(label: "Daily Goal", value: "\(profile?.dailyGoalMinutes ?? appState.dailyGoalMinutes) minutes")
                profileRow(label: "Hangul Complete", value: (profile?.hangulCompleted ?? false) ? "Yes" : "In Progress")
            }

            Section("Account") {
                if appState.isAuthenticated {
                    profileRow(label: "User ID", value: appState.currentUserId?.uuidString.prefix(8).map(String.init).joined() ?? "—")
                    profileRow(label: "Subscription", value: appState.subscriptionTier.rawValue.capitalized)
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Sign in to sync your progress across devices")
                            .font(.subheadline)
                    }

                    NavigationLink("Sign In") {
                        AuthView { session in
                            appState.isAuthenticated = true
                            appState.currentUserId = session.userId
                        }
                    }
                }
            }

            Section("Statistics") {
                profileRow(label: "Member Since", value: formattedDate(profile?.createdAt))
                profileRow(label: "Onboarding", value: (profile?.onboardingCompleted ?? false) ? "Complete" : "Incomplete")
            }
        }
        .navigationTitle("Profile")
        .onAppear { loadProfile() }
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func loadProfile() {
        let descriptor = FetchDescriptor<LearnerProfile>()
        profile = (try? modelContext.fetch(descriptor))?.first
    }
}
