import XCTest
@testable import HallyuCore

final class NetworkMonitorTests: XCTestCase {

    // MARK: - Initialization Tests

    func testNetworkMonitorInitialState() {
        let monitor = NetworkMonitor()
        XCTAssertTrue(monitor.isConnected, "Network monitor should default to connected")
        XCTAssertEqual(monitor.connectionType, .unknown, "Connection type should default to unknown")
    }

    func testNetworkMonitorStartAndStop() {
        let monitor = NetworkMonitor()
        // Should not crash when starting and stopping
        monitor.start()
        monitor.stop()
    }

    // MARK: - Connection Type Tests

    func testConnectionTypeRawValues() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wifi.rawValue, "wifi")
        XCTAssertEqual(NetworkMonitor.ConnectionType.cellular.rawValue, "cellular")
        XCTAssertEqual(NetworkMonitor.ConnectionType.wiredEthernet.rawValue, "wiredEthernet")
        XCTAssertEqual(NetworkMonitor.ConnectionType.unknown.rawValue, "unknown")
    }
}
