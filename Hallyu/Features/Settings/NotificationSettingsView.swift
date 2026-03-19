import SwiftUI

struct NotificationSettingsView: View {
    @Environment(ServiceContainer.self) private var services
    let notificationService: NotificationService

    @State private var isEnabled: Bool = true
    @State private var reminderHour: Int = 9
    @State private var reminderMinute: Int = 0
    @State private var showAuthAlert: Bool = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: $isEnabled) {
                    Label("Review Reminders", systemImage: "bell.fill")
                }
                .accessibilityLabel("Review Reminders")
                .accessibilityHint("Toggle daily review notifications")
                .onChange(of: isEnabled) { _, newValue in
                    updatePreferences()
                    if newValue {
                        Task { await requestAuthIfNeeded() }
                    }
                }
            } footer: {
                Text("Get a daily reminder when you have items ready for review.")
            }

            if isEnabled {
                Section("Reminder Time") {
                    DatePicker(
                        "Time",
                        selection: reminderDateBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .accessibilityLabel("Reminder time")
                    .accessibilityHint("Choose when you want to be reminded to review")
                    .onChange(of: reminderHour) { _, _ in updatePreferences() }
                    .onChange(of: reminderMinute) { _, _ in updatePreferences() }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("What you'll get", systemImage: "info.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        notificationTypeRow(
                            icon: "arrow.counterclockwise",
                            title: "Review Reminders",
                            description: "When SRS items are due"
                        )
                        notificationTypeRow(
                            icon: "flame.fill",
                            title: "Streak Reminders",
                            description: "Evening nudge if you haven't studied"
                        )
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            isEnabled = notificationService.notificationsEnabled
            reminderHour = notificationService.preferredReminderHour
            reminderMinute = notificationService.preferredReminderMinute
        }
        .alert("Notifications Disabled", isPresented: $showAuthAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                isEnabled = false
            }
        } message: {
            Text("Please enable notifications in Settings to receive review reminders.")
        }
    }

    private func notificationTypeRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 9
                reminderMinute = components.minute ?? 0
            }
        )
    }

    private func updatePreferences() {
        notificationService.updatePreferences(
            enabled: isEnabled,
            hour: reminderHour,
            minute: reminderMinute
        )
    }

    private func requestAuthIfNeeded() async {
        if !notificationService.isAuthorized {
            let granted = await notificationService.requestAuthorization()
            if !granted {
                await MainActor.run { showAuthAlert = true }
            }
        }
    }
}
