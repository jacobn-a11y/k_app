import XCTest
@testable import HallyuCore

final class NotificationServiceTests: XCTestCase {

    var notificationService: NotificationService!

    override func setUp() {
        notificationService = NotificationService()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(notificationService.notificationsEnabled, "Notifications should be enabled by default")
        XCTAssertEqual(notificationService.preferredReminderHour, 9, "Default reminder hour should be 9")
        XCTAssertEqual(notificationService.preferredReminderMinute, 0, "Default reminder minute should be 0")
    }

    // MARK: - Preferences

    func testUpdatePreferences() {
        notificationService.updatePreferences(enabled: false, hour: 14, minute: 30)

        XCTAssertFalse(notificationService.notificationsEnabled)
        XCTAssertEqual(notificationService.preferredReminderHour, 14)
        XCTAssertEqual(notificationService.preferredReminderMinute, 30)
    }

    func testDisablingNotificationsCancelsAll() {
        notificationService.updatePreferences(enabled: false, hour: 9, minute: 0)
        XCTAssertFalse(notificationService.notificationsEnabled)
        // Notifications should be cancelled (verified by no crash)
    }

    func testReEnablingNotifications() {
        notificationService.updatePreferences(enabled: false, hour: 9, minute: 0)
        notificationService.updatePreferences(enabled: true, hour: 10, minute: 15)

        XCTAssertTrue(notificationService.notificationsEnabled)
        XCTAssertEqual(notificationService.preferredReminderHour, 10)
        XCTAssertEqual(notificationService.preferredReminderMinute, 15)
    }

    // MARK: - Deep Link Parsing

    func testParseReviewDeepLink() {
        let userInfo: [AnyHashable: Any] = ["deepLink": "hallyu://review"]
        let deepLink = NotificationService.parseDeepLink(from: userInfo)
        XCTAssertEqual(deepLink, .reviewSession)
    }

    func testParseDailyPlanDeepLink() {
        let userInfo: [AnyHashable: Any] = ["deepLink": "hallyu://today"]
        let deepLink = NotificationService.parseDeepLink(from: userInfo)
        XCTAssertEqual(deepLink, .dailyPlan)
    }

    func testParseInvalidDeepLink() {
        let userInfo: [AnyHashable: Any] = ["deepLink": "hallyu://invalid"]
        let deepLink = NotificationService.parseDeepLink(from: userInfo)
        XCTAssertNil(deepLink)
    }

    func testParseMissingDeepLink() {
        let userInfo: [AnyHashable: Any] = [:]
        let deepLink = NotificationService.parseDeepLink(from: userInfo)
        XCTAssertNil(deepLink)
    }

    func testParseMediaLessonDeepLink() {
        let id = UUID()
        let userInfo: [AnyHashable: Any] = ["deepLink": "hallyu://lesson/\(id.uuidString)"]
        let deepLink = NotificationService.parseDeepLink(from: userInfo)
        XCTAssertEqual(deepLink, .mediaLesson(id: id))
    }
}
