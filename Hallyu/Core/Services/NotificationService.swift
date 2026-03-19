import Foundation
import UserNotifications
import Observation
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class NotificationService: @unchecked Sendable {
    var isAuthorized: Bool = false
    var notificationsEnabled: Bool = true
    var preferredReminderHour: Int = 9
    var preferredReminderMinute: Int = 0
    var apnsDeviceTokenHex: String?
    var lastPushSyncError: String?

    private let center = UNUserNotificationCenter.current()
    private let prefsKey = "notificationPreferences"
    private let apnsTokenKey = "apnsDeviceTokenHex"
    private var apnsObservers: [NSObjectProtocol] = []
    private var pushRegistrationHandler: ((PushRegistrationPayload) async throws -> Void)?

    init() {
        loadPreferences()
        subscribeToAPNSEvents()
    }

    deinit {
        apnsObservers.forEach(NotificationCenter.default.removeObserver)
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
            if granted {
                registerForRemoteNotificationsIfAuthorized()
                await syncPushRegistrationIfPossible()
            }
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
        if isAuthorized {
            registerForRemoteNotificationsIfAuthorized()
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
        await syncPushRegistrationIfPossible()
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
        await syncPushRegistrationIfPossible()
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - APNs + Backend Registration

    struct PushRegistrationPayload: Equatable, Sendable {
        let deviceToken: String
        let notificationsEnabled: Bool
        let reminderHour: Int
        let reminderMinute: Int
    }

    func configurePushRegistrationHandler(
        _ handler: @escaping (PushRegistrationPayload) async throws -> Void
    ) {
        pushRegistrationHandler = handler
        Task { await syncPushRegistrationIfPossible() }
    }

    func refreshPushRegistration() async {
        await syncPushRegistrationIfPossible()
    }

    func handleAPNsDeviceToken(_ tokenData: Data) {
        let tokenHex = Self.hexString(from: tokenData)
        guard !tokenHex.isEmpty else { return }
        apnsDeviceTokenHex = tokenHex
        savePreferences()
        Task { await syncPushRegistrationIfPossible() }
    }

    func handleAPNsRegistrationError(_ error: Error) {
        lastPushSyncError = error.localizedDescription
    }

    func registerForRemoteNotificationsIfAuthorized() {
        #if canImport(UIKit)
        guard isAuthorized else { return }
        UIApplication.shared.registerForRemoteNotifications()
        #endif
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

        Task { await syncPushRegistrationIfPossible() }
    }

    private func savePreferences() {
        let prefs: [String: Any] = [
            "enabled": notificationsEnabled,
            "hour": preferredReminderHour,
            "minute": preferredReminderMinute,
            apnsTokenKey: apnsDeviceTokenHex as Any
        ]
        UserDefaults.standard.set(prefs, forKey: prefsKey)
    }

    private func loadPreferences() {
        guard let prefs = UserDefaults.standard.dictionary(forKey: prefsKey) else { return }
        notificationsEnabled = prefs["enabled"] as? Bool ?? true
        preferredReminderHour = prefs["hour"] as? Int ?? 9
        preferredReminderMinute = prefs["minute"] as? Int ?? 0
        apnsDeviceTokenHex = prefs[apnsTokenKey] as? String
    }

    private func subscribeToAPNSEvents() {
        let center = NotificationCenter.default

        let tokenObserver = center.addObserver(
            forName: .hallyuDidRegisterForRemoteNotifications,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let data = note.userInfo?["deviceToken"] as? Data else { return }
            self?.handleAPNsDeviceToken(data)
        }

        let errorObserver = center.addObserver(
            forName: .hallyuDidFailToRegisterForRemoteNotifications,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let error = note.userInfo?["error"] as? Error else { return }
            self?.handleAPNsRegistrationError(error)
        }

        apnsObservers = [tokenObserver, errorObserver]
    }

    private func syncPushRegistrationIfPossible() async {
        guard let token = apnsDeviceTokenHex,
              let handler = pushRegistrationHandler else {
            return
        }

        let payload = PushRegistrationPayload(
            deviceToken: token,
            notificationsEnabled: notificationsEnabled && isAuthorized,
            reminderHour: preferredReminderHour,
            reminderMinute: preferredReminderMinute
        )

        do {
            try await handler(payload)
            await MainActor.run { lastPushSyncError = nil }
        } catch {
            await MainActor.run { lastPushSyncError = error.localizedDescription }
        }
    }

    static func hexString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Deep Link

enum DeepLink: Equatable {
    case reviewSession
    case dailyPlan
    case mediaLesson(id: UUID)
}

extension Notification.Name {
    static let hallyuDidRegisterForRemoteNotifications =
        Notification.Name("hallyuDidRegisterForRemoteNotifications")
    static let hallyuDidFailToRegisterForRemoteNotifications =
        Notification.Name("hallyuDidFailToRegisterForRemoteNotifications")
}
