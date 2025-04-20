import Foundation

struct TrafficStats: Codable {
    var bytesIn: UInt64 = 0
    var bytesOut: UInt64 = 0
    var startTime: Date
    var lastUpdated: Date
    
    var totalBytes: UInt64 {
        bytesIn + bytesOut
    }
    
    var duration: TimeInterval {
        lastUpdated.timeIntervalSince(startTime)
    }
    
    var speedIn: Double {
        Double(bytesIn) / duration
    }
    
    var speedOut: Double {
        Double(bytesOut) / duration
    }
    
    init() {
        let now = Date()
        self.startTime = now
        self.lastUpdated = now
    }
    
    mutating func addInbound(_ bytes: UInt64) {
        bytesIn += bytes
        lastUpdated = Date()
    }
    
    mutating func addOutbound(_ bytes: UInt64) {
        bytesOut += bytes
        lastUpdated = Date()
    }
    
    mutating func reset() {
        bytesIn = 0
        bytesOut = 0
        let now = Date()
        startTime = now
        lastUpdated = now
    }
}

extension TrafficStats {
    static func formatBytes(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        
        while value > 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", value, units[unitIndex])
    }
    
    static func formatSpeed(_ bytesPerSecond: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
        var value = bytesPerSecond
        var unitIndex = 0
        
        while value > 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", value, units[unitIndex])
    }
} 