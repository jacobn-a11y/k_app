import Foundation
import Testing
@testable import HallyuCore

@Suite("NotificationService Tests")
struct NotificationServiceTests {
    @Test("Device token data is converted to lowercase hex")
    func deviceTokenHexEncoding() {
        let token = Data([0xAB, 0xCD, 0x01, 0xEF])
        let hex = NotificationService.hexString(from: token)
        #expect(hex == "abcd01ef")
    }

    @Test("Handling APNs token stores token on service")
    func storesApnsToken() {
        let service = NotificationService()
        service.handleAPNsDeviceToken(Data([0xDE, 0xAD, 0xBE, 0xEF]))
        #expect(service.apnsDeviceTokenHex == "deadbeef")
    }

    @Test("Review deep link routes to review session")
    func deepLinkReview() {
        let route = NotificationService.parseDeepLink(from: ["deepLink": "hallyu://review"])
        #expect(route == .reviewSession)
    }

    @Test("Invalid deep link returns nil")
    func deepLinkInvalid() {
        let route = NotificationService.parseDeepLink(from: ["deepLink": "invalid://route"])
        #expect(route == nil)
    }
}
