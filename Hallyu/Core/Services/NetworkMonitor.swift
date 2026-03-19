import Foundation
import Network
import Observation

@Observable
final class NetworkMonitor: @unchecked Sendable {
    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType: String {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue

    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.hallyu.networkmonitor")
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.mapConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }

    private func mapConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .unknown
    }
}
