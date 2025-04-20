import Foundation
import JavaScriptCore

struct PACConfig: Codable {
    var script: String
    var lastUpdated: Date
    var url: URL?
    
    static var defaultScript: String {
        """
        function FindProxyForURL(url, host) {
            return "DIRECT";
        }
        """
    }
    
    static var `default`: PACConfig {
        PACConfig(
            script: defaultScript,
            lastUpdated: Date(),
            url: nil
        )
    }
}

enum PACResult {
    case direct
    case proxy(host: String, port: Int)
    case error(String)
    
    static func parse(_ result: String) -> PACResult {
        let components = result.split(separator: " ")
        switch components.first?.uppercased() {
        case "DIRECT":
            return .direct
        case "PROXY":
            guard components.count > 1,
                  let hostPort = components.last,
                  let colonIndex = hostPort.firstIndex(of: ":"),
                  let port = Int(hostPort[hostPort.index(after: colonIndex)...]) else {
                return .error("Invalid PROXY format")
            }
            let host = String(hostPort[..<colonIndex])
            return .proxy(host: host, port: port)
        default:
            return .error("Unsupported proxy type")
        }
    }
} 