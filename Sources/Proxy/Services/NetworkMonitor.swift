import Foundation
import Network
import Logging

class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let logger = Logger(label: "com.proxy.network")
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private(set) var isConnected = false
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            self.isConnected = path.status == .satisfied
            self.connectionType = self.getConnectionType(path)
            
            self.logger.info("Network status changed: \(self.isConnected ? "Connected" : "Disconnected") via \(self.connectionType)")
        }
        
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    // 获取当前网络速度
    func getCurrentBandwidth() -> (upload: Double, download: Double) {
        // TODO: 实现网络速度监测
        return (0, 0)
    }
    
    // 获取网络延迟
    func getLatency(for host: String, completion: @escaping (TimeInterval?) -> Void) {
        // 创建ICMP请求来测试延迟
        DispatchQueue.global().async {
            // TODO: 实现ping测试
            completion(nil)
        }
    }
} 