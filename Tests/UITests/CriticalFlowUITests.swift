#if canImport(UIKit)
import XCTest

final class CriticalFlowUITests: XCTestCase {
    private func makeAppOrSkip() throws -> XCUIApplication {
        guard let bundleId = ProcessInfo.processInfo.environment["HALLYU_UI_TEST_BUNDLE_ID"],
              !bundleId.isEmpty else {
            throw XCTSkip("Set HALLYU_UI_TEST_BUNDLE_ID to run XCUITests with a host app.")
        }

        let app = XCUIApplication(bundleIdentifier: bundleId)
        app.launchArguments.append("-ui_testing")
        app.launchArguments.append("1")
        return app
    }

    func testOnboardingFlowSmoke() throws {
        let app = try makeAppOrSkip()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
        XCTAssertTrue(app.staticTexts["Learn Korean through\nthe media you love"].exists)
    }

    func testReviewFlowDeepLinkLaunch() throws {
        let app = try makeAppOrSkip()
        app.launchArguments.append("-deeplink")
        app.launchArguments.append("hallyu://review")
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
    }

    func testMediaLessonFlowDeepLinkLaunch() throws {
        let app = try makeAppOrSkip()
        app.launchArguments.append("-deeplink")
        app.launchArguments.append("hallyu://today")
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
    }
}
#endif
