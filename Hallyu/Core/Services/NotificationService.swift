import Foundation
import UserNotifications
import Observation

@Observable
final class NotificationService: @unchecked Sendable {
    var isAuthorized: Bool = false
    var notificationsEnabled: Bool = true
    var preferredReminderHour: Int = 9
    var preferredReminderMinute: Int = 0

    private let center = UNUserNotificationCenter.current()
    private let prefsKey = "notificationPreferences"

    init() {
        loadPreferences()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - SRS Review Reminders

    func scheduleDailyReviewReminder(pendingReviewCount: Int) async {
        guard notificationsEnabled, isAuthorized else { return }

        // Remove existing review reminders
        center.removePendingNotificationRequests(withIdentifiers: ["daily_review_reminder"])

        guard pendingReviewCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Review!"
        content.body = pendingReviewCount == 1
            ? "You have 1 item ready for review. Keep your streak going!"
            : "You have \(pendingReviewCount) items ready for review. Keep your streak going!"
        content.sound = .default
        content.badge = NSNumber(value: pendingReviewCount)
        content.categoryIdentifier = "REVIEW_REMINDER"
        content.userInfo = ["deepLink": "hallyu://review"]

        var dateComponents = DateComponents()
        dateComponents.hour = preferredReminderHour
        dateComponents.minute = preferredReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_review_reminder",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func scheduleStreakReminder() async {
        guard notificationsEnabled, isAuthorized else { return }

        center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        content.body = "You haven't studied today. Just 5 minutes keeps your streak alive."
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"
        content.userInfo = ["deepLink": "hallyu://today"]

        // Schedule for 8 PM if user hasn't studied
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Deep Link Handling

    static func parseDeepLink(from userInfo: [AnyHashable: Any]) -> DeepLink? {
        guard let urlString = userInfo["deepLink"] as? String,
              let url = URL(string: urlString) else {
            return nil
        }

        switch url.host {
        case "review":
            return .reviewSession
        case "today":
            return .dailyPlan
        case "lesson":
            if let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                return .mediaLesson(id: id)
            }
            return .dailyPlan
        default:
            return nil
        }
    }

    // MARK: - Notification Categories

    func registerCategories() {
        let reviewAction = UNNotificationAction(
            identifier: "START_REVIEW",
            title: "Start Review",
            options: [.foreground]
        )

        let laterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind Me Later"
        )

        let reviewCategory = UNNotificationCategory(
            identifier: "REVIEW_REMINDER",
            actions: [reviewAction, laterAction],
            intentIdentifiers: []
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [reviewAction, laterAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([reviewCategory, streakCategory])
    }

    // MARK: - Preferences

    func updatePreferences(enabled: Bool, hour: Int, minute: Int) {
        notificationsEnabled = enabled
        preferredReminderHour = hour
        preferredReminderMinute = minute
        savePreferences()

        if !enabled {
            cancelAllNotifications()
        }
    }

    private func savePreferences() {
        let prefs: [String: Any] = [
            "enabled": notificationsEnabled,
            "hour": preferredReminderHour,
            "minute": preferredReminderMinute
        ]
        UserDefaults.standard.set(prefs, forKey: prefsKey)
    }

    private func loadPreferences() {
        guard let prefs = UserDefaults.standard.dictionary(forKey: prefsKey) else { return }
        notificationsEnabled = prefs["enabled"] as? Bool ?? true
        preferredReminderHour = prefs["hour"] as? Int ?? 9
        preferredReminderMinute = prefs["minute"] as? Int ?? 0
    }
}

// MARK: - Deep Link

enum DeepLink: Equatable {
    case reviewSession
    case dailyPlan
    case mediaLesson(id: UUID)
}
