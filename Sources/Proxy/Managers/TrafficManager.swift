import Foundation

class TrafficManager {
    static let shared = TrafficManager()
    
    @Published private(set) var stats = TrafficStats()
    private let queue = DispatchQueue(label: "com.proxy.trafficstats")
    
    private init() {}
    
    func addInboundTraffic(_ bytes: UInt64) {
        queue.async {
            self.stats.addInbound(bytes)
        }
    }
    
    func addOutboundTraffic(_ bytes: UInt64) {
        queue.async {
            self.stats.addOutbound(bytes)
        }
    }
    
    func resetStats() {
        queue.async {
            self.stats.reset()
        }
    }
    
    func getFormattedStats() -> (inbound: String, outbound: String, speedIn: String, speedOut: String) {
        let stats = self.stats // 获取当前快照
        return (
            inbound: TrafficStats.formatBytes(stats.bytesIn),
            outbound: TrafficStats.formatBytes(stats.bytesOut),
            speedIn: TrafficStats.formatSpeed(stats.speedIn),
            speedOut: TrafficStats.formatSpeed(stats.speedOut)
        )
    }
} 